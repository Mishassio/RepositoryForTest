module test_module #(parameter DATA_W = 8)
(
  input  logic                    clk_in,
  input  logic                    reset_in,
  input  logic [(DATA_W - 1) : 0] data_in    ,
  output logic [(DATA_W - 1) : 0] out_0      ,
  output logic                    out_valid_0,
  output logic [(DATA_W - 1) : 0] out_1      ,
  output logic                    out_valid_1,
  output logic [(DATA_W - 1) : 0] out_2      ,
  output logic                    out_valid_2,
  output logic [(DATA_W - 1) : 0] out_3      , 
  output logic                    out_valid_3 
);

localparam int unsigned  DEPTH = 4         ;
logic [(DATA_W - 1) : 0] rx_buf            ;
logic [(DATA_W - 1) : 0] valid_buf         ;
logic [(DATA_W - 1) : 0] out_i      [DEPTH];
logic                    out_valid_i[DEPTH];
wire  [(DEPTH-1):1]      shift_enable      ;
wire  [(DEPTH-1):0]      eq_vector         ;
wire                     is_unique         ;

always @(posedge clk_in) begin
  if(1'b1 === reset_in) begin
    rx_buf         <= '0;
    valid_buf      <= 1'b0;
    out_i[0]       <= '0;
    out_valid_i[0] <= 1'b0;
  end else begin
    rx_buf         <= data_in;
    valid_buf      <= 1'b1;
    out_i[0]       <= rx_buf;
    out_valid_i[0] <= valid_buf;
  end
end

assign is_unique = ~(|(eq_vector));

for(genvar k = 0; k < DEPTH; k++) begin
  assign eq_vector[k]  = (rx_buf === out_i[k]) & out_valid_i[k];

  if(k>0) begin
    assign shift_enable[k] = (|(eq_vector[(DEPTH-1):k])) | is_unique;
    always@(posedge clk_in) begin
      if(1'b1 === reset_in) begin
        out_i[k] <= '0;
        out_valid_i[k] <= 1'b0;
      end else begin
        if(1'b1 === shift_enable[k]) begin
          out_i[k] <= out_i[k-1];
        end
        if(1'b1 === is_unique) begin
          out_valid_i[k] <= out_valid_i[k-1];
        end
      end
    end
  end
end

assign out_0       = out_i      [0];
assign out_valid_0 = out_valid_i[0];
assign out_1       = out_i      [1];
assign out_valid_1 = out_valid_i[1];
assign out_2       = out_i      [2];
assign out_valid_2 = out_valid_i[2];
assign out_3       = out_i      [3];
assign out_valid_3 = out_valid_i[3];

endmodule

/* TESTBENCH

`timescale 1ps/1ps

`include "test_module2.sv"

module top_tb;

  localparam int unsigned  DATA_W = 8 ;

  bit clk_in;
  bit reset_in=1;
  logic [(DATA_W - 1) : 0] data_in;
  logic [(DATA_W - 1) : 0] out_0;
  logic out_valid_0;
  logic [(DATA_W - 1) : 0] out_1;
  logic out_valid_1;
  logic [(DATA_W - 1) : 0] out_2;
  logic out_valid_2;
  logic [(DATA_W - 1) : 0] out_3;
  logic out_valid_3;

  assign #1000ns clk_in = ~clk_in;

  test_module#(DATA_W) test_module_0(
    .clk_in     (clk_in     ),
    .reset_in   (reset_in   ),
    .data_in    (data_in    ),
    .out_0      (out_0      ),
    .out_valid_0(out_valid_0),
    .out_1      (out_1      ),
    .out_valid_1(out_valid_1),
    .out_2      (out_2      ),
    .out_valid_2(out_valid_2),
    .out_3      (out_3      ),
    .out_valid_3(out_valid_3) 
  );

  localparam int unsigned  DEPTH = 4;
  logic [(DATA_W) : 0] out_i[DEPTH];
  
  `define SEND_TEST_FLOW(flow) \
    foreach (``flow``[i]) begin\
      data_in <= ``flow``[i];  \
      @(posedge clk_in);       \
    end

  initial begin
    automatic logic[DATA_W-1:0] test_vector1[] = '{1 ,2, 1, 2, 1, 2, 1};
    automatic logic[DATA_W-1:0] test_vector2[] = '{1, 2, 3, 4, 3, 2, 3, 4, 3, 4,1};
    $monitor( "%0t:\nout_0: %0d, out_valid_0: %0b; \nout_1: %0d, out_valid_1: %0b;\nout_2: %0d, out_valid_2: %0b;\nout_3: %0d, out_valid_3: %0b\n",
              $time, out_0,      out_valid_0,        out_1,      out_valid_1,       out_2,      out_valid_2,       out_3,      out_valid_3);
    repeat(10) @(posedge clk_in);
    reset_in <= 1;
    repeat(10) @(posedge clk_in);
    reset_in <= 0;
    `SEND_TEST_FLOW(test_vector1)
    repeat(4) @(posedge clk_in);
    `SEND_TEST_FLOW(test_vector2)

    repeat(10) begin
      automatic logic[DATA_W-1:0] test_vector[];
      void'(std::randomize(test_vector) with {test_vector.size() < 100;});
      repeat(4) @(posedge clk_in);
      `SEND_TEST_FLOW(test_vector)
    end
    $finish();
  end

  assign out_i[0] = {out_0,out_valid_0};
  assign out_i[1] = {out_1,out_valid_1};
  assign out_i[2] = {out_2,out_valid_2};
  assign out_i[3] = {out_3,out_valid_3};
  //Uniqness check only
  always@(posedge clk_in) begin
    automatic logic [(DATA_W) : 0]  valid_que[$] = out_i.find() with (item[0] === 1'b1);
    if(valid_que.size() > 0) begin
      automatic  logic [(DATA_W) : 0]  unique_valid_que[$] = valid_que.unique();
      if(unique_valid_que.size() != valid_que.size()) begin
        $error("%0t: uniqness error", $time);
      end
    end
  end

endmodule

*/
