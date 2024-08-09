`timescale 1ns / 1ps
module tb(

    );
    
    wire clk, rstn, in_valid ;
    wire signed [6:0] in_data ;
    //wire [3:0] op ;
    wire out_valid ;
    wire signed [6:0] out_data ;

    IDC     module0(.clk(clk), .rstn(rstn), .in_valid(in_valid), .in_data(in_data), /*.op(op),*/ .out_valid(out_valid), .out_data(out_data)) ;
    pattern module1(.clk(clk), .rstn(rstn), .in_valid(in_valid), .in_data(in_data), /*.op(op),*/ .out_valid(out_valid), .out_data(out_data)) ;
endmodule
