// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.2 (win64) Build 1909853 Thu Jun 15 18:39:09 MDT 2017
// Date        : Wed Sep 13 20:23:17 2017
// Host        : Polytech-PC running 64-bit Service Pack 1  (build 7601)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/Polytech/Desktop/projplasma/plasma/vhdl/plasma_hw/plasma_hw.srcs/sources_1/ip/PROM_Obst/PROM_Obst_stub.v
// Design      : PROM_Obst
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_6,Vivado 2017.2" *)
module PROM_Obst(clka, addra, douta, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,addra[11:0],douta[11:0],clkb,addrb[11:0],doutb[11:0]" */;
  input clka;
  input [11:0]addra;
  output [11:0]douta;
  input clkb;
  input [11:0]addrb;
  output [11:0]doutb;
endmodule
