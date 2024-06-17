`timescale 1ns / 1ps

module BUS_interconntor (
    input  logic [31:0] address,
    output logic [ 4:0] slave_sel,
    input  logic [31:0] slave_rdata1,
    input  logic [31:0] slave_rdata2,
    input  logic [31:0] slave_rdata3,
    input  logic [31:0] slave_rdata4,
    input  logic [31:0] slave_rdata5,
    output logic [31:0] master_rdata
);
 
  decoder U_Decoder (
      .x(address),
      .y(slave_sel)
  );
  mux U_MUX (
      .sel(address),
      .a  (slave_rdata1),
      .b  (slave_rdata2),
      .c  (slave_rdata3),
      .d  (slave_rdata4),
      .e  (slave_rdata5),
      .y  (master_rdata)
  );

endmodule

module decoder (
    input  logic [31:0] x,
    output logic [ 4:0] y
);

  always_comb begin : decoder
    y = 5'b0;
    case (x[31:8])
      //RAM
      24'h0000_00: y = 5'b00001;
      //GPIO
      24'h0000_10: y = 5'b00010;
      24'h0000_12: y = 5'b00010;
      24'h0000_14: y = 5'b00010; 
      24'h0000_16: y = 5'b00010;
      24'h0000_18: y = 5'b00010;
      24'h0000_1A: y = 5'b00010;
      24'h0000_1B: y = 5'b00010;
      //Timer
      24'h0000_1C: y = 5'b00100;
      24'h0000_1E: y = 5'b00100;
      24'h0000_20: y = 5'b00100;
      24'h0000_22: y = 5'b00100;
      //UART
      24'h0000_24: y = 5'b01000;
      24'h0000_26: y = 5'b01000;
      //FND
      24'h0000_30: y = 5'b10000;
      default:     y = 5'b0;
    endcase
  end

endmodule

module mux (
    input  logic [31:0] sel,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] c,
    input  logic [31:0] d,
    input  logic [31:0] e,
    output logic [31:0] y
);
  always_comb begin : decoder
    y = 32'b0;
    case (sel[31:8])
      //RAM
      24'h0000_00: y = a;
      //GPIO
      24'h0000_10: y = b;
      24'h0000_12: y = b;
      24'h0000_14: y = b;
      24'h0000_16: y = b;
      24'h0000_18: y = b;
      24'h0000_1A: y = b;
      24'h0000_1B: y = b;
      //Timer
      24'h0000_1C: y = c;
      24'h0000_1E: y = c;
      24'h0000_20: y = c;
      24'h0000_22: y = c;
      //UART
      24'h0000_24: y = d;
      24'h0000_26: y = d;
      //FND
      24'h0000_30: y = e;
      default:     y = 32'b0;
    endcase
  end

endmodule
