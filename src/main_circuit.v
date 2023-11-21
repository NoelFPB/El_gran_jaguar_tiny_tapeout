

`default_nettype none

module tt_um_chip_SP_Soy_de_Zacapa(
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // rst_n_n - low to rst_n
);

wire n_reset;
wire [3:0] out;
wire [3:0] address;
wire [3:0]entrada;
wire [7:0]instr;
// To use the bidirectional pins as input
assign uio_oe = 8'h0;
assign uio_out = 8'h0;
// Inputs
assign n_reset = uio_in[0];
assign entrada = uio_in[4:1];
assign instr = ui_in;

// Outputs
assign uo_out[3:0] = address;
assign uo_out[7:4] = out;


//--------------------------------
// module cpu(
//   input clk,
//   input n_reset,
//   output [3:0] address,
//   input [7:0] instr,
//   input [3:0] entrada,
//   output [3:0] out);

  //------------------------
  // （デバッグ用）モニタの設定
  //------------------------
  //initial begin
    // $monitor("%t: pc = %b, a = %b, b = %b, instr = %b, op = %b, im = %b, select_a = %b, select_b = %b, load0 = %b, load1 = %b, load2 = %b", $time, pc_reg, a_reg, b_reg, instr, op, im, select_a, select_b, load0, load1, load2);
  //end

  //------------------------
  // ワイヤ・レジスタの宣言
  //------------------------
  wire [3:0] op;
  wire [3:0] im;
  wire select_a, select_b;
  wire load0, load1, load2, load3;
  wire [3:0] selector_out;
  wire [3:0] alu_out;
  wire c; // Carry out

  reg [3:0] pc_reg; // Program counter
  reg [3:0] a_reg, b_reg; // A, B register
  reg [3:0] out_reg; // Out port register
  reg co_reg; // Carry out register

  //------------------------
  // 外部モジュールとの接続
  //------------------------

  // データセレクタ
  data_selector ds (a_reg, b_reg, entrada, 4'b0000, select_a, select_b, selector_out);

  //------------------------
  // レジスタ
  //------------------------
  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) begin
      a_reg <= 0;
      b_reg <= 0;
    end
    else begin
      a_reg <= load0 ? alu_out : a_reg;
      b_reg <= load1 ? alu_out : b_reg;
    end
  end

  //------------------------
  // 出力ポート
  //------------------------
  assign out = out_reg;

  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) out_reg <= 0;
    else out_reg <= load2 ? alu_out : out_reg;
  end

  //------------------------
  // プログラムカウンタ
  //------------------------
  assign address = pc_reg;

  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) pc_reg <= 0;
    else pc_reg <= load3 ? im : pc_reg + 1;
  end

  //------------------------
  // ALU と carry レジスタ
  //------------------------
  assign {c, alu_out} = selector_out + im;

  always @(posedge clk or negedge n_reset) begin
    if (!n_reset) co_reg <= 0;
    else co_reg <= c;
  end

  //------------------------
  // 命令のデコード
  //------------------------

  // 命令を「オペレーションコード」と「イミディエイトデータ」へ分割
  assign op = instr[7:4]; // オペレーションコード
  assign im = instr[3:0]; // イミディエイトデータ

  // データセレクタ制御フラグ
  assign select_a = op[0] | op[3];
  assign select_b = op[1];

  // ロードレジスタ制御フラグ
  assign load0 = !(op[2] | op[3]); // Aレジスタへロード
  assign load1 = !(!op[2] | op[3]); // Bレジスタへロード
  assign load2 = !op[2] & op[3]; // 出力ポートへロード
  assign load3 = (!co_reg | op[0]) & op[2] & op[3]; // PCへロード


endmodule

//------------------------
// データセレクタ
//
// select_a、select_bの信号に応じてc0〜c3の信号を出力する
//
// * (select_a = L, select_b = L) => c0を出力
// * (select_a = H, select_b = L) => c1を出力
// * (select_a = L, select_b = H) => c2を出力
// * (select_a = H, select_b = H) => c3を出力
//------------------------
module data_selector(
  input [3:0] c0,
  input [3:0] c1,
  input [3:0] c2,
  input [3:0] c3,
  input select_a, select_b,
  output reg [3:0] y
);

  always @(*) begin
    if (select_a & select_b)
      y = c3;
    else if (!select_a & select_b)
      y = c2;
    else if (select_a & !select_b)
      y = c1;
    else
      y = c0;
  end
endmodule


//------------------------
// テストベンチ
// （ラーメンタイマーを実行して、out を $display するだけ）
// iverilog -o a cpu.v && ./a
//------------------------
// module cpu_test();
//   reg clk;
//   reg n_reset;
//   reg [3:0] port_in;

//   wire [3:0] address;
//   wire [7:0] dout;
//   wire [3:0] port_out;

//   // Generate clock
//   always begin
//     #5 clk = 1;
//     #5 clk = 0;
//   end

//   cpu cpu(clk, n_reset, address, dout, port_in, port_out);
//   test_rom rom(address, dout);

//   // Finish after 3000 unit times
//   always
//     #3000 $finish;

//   initial begin
//     // 波形データを cpu_test.vcd へ出力する
//     $dumpfile("cpu_test.vcd");

//     // cpu モジュール内の変数を波形データとして出力
//     $dumpvars(0, cpu);

//     // 出力ポートをモニタする
//     $monitor("%t: out = %b", $time, port_out);
//   end

//   initial begin
//     // Init variables
//     #0 clk = 0; n_reset = 1; port_in = 4'b0101;

//     // Reset cpu
//     #10 n_reset = 0;
//     #10 n_reset = 1;
//   end
// endmodule

//------------------------
// ROM
//------------------------
// module test_rom(
//   input [3:0] address,
//   output reg [7:0] dout
// );

//   always @(address)
//     case (address)
//       /*
//         ラーメンタイマー
//       */
//       4'b0000: dout <= 8'b10110111;
//       4'b0001: dout <= 8'b00000001;
//       4'b0010: dout <= 8'b11100001;
//       4'b0011: dout <= 8'b00000001;
//       4'b0100: dout <= 8'b11100011;
//       4'b0101: dout <= 8'b10110110;
//       4'b0110: dout <= 8'b00000001;
//       4'b0111: dout <= 8'b11100110;
//       4'b1000: dout <= 8'b00000001;
//       4'b1001: dout <= 8'b11101000;
//       4'b1010: dout <= 8'b10110000;
//       4'b1011: dout <= 8'b10110100;
//       4'b1100: dout <= 8'b00000001;
//       4'b1101: dout <= 8'b11101010;
//       4'b1110: dout <= 8'b10111000;
//       4'b1111: dout <= 8'b11111111;
//       default: dout <= 8'bxxxxxxxx;
//     endcase
// endmodule
