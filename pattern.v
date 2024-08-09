`timescale 1ns / 1ps
module pattern(
output reg clk, rstn, in_valid,
output reg signed [6:0] in_data,
//output reg [3:0] op,
input out_valid,
input signed [6:0] out_data
    );
    integer CYCLE = 60 ;
    integer k ;
    integer input_file ;
    integer read ;
    reg signed [6:0] input_data ;
    
    initial clk = 0 ;
    always #(CYCLE/2) clk = ~clk ;
    
    initial begin
        rstn = 0 ;
        in_valid = 0 ;
        #(2.5*CYCLE) ;
        rstn = 1 ;
        #(2.5*CYCLE) ;
        in_valid = 1'b1 ;
        input_file = $fopen("D:/workspace/verilog practice/Vivado/240808/IDC/in_file.txt", "r") ;
        @(negedge clk);
        for(k=0; k<(64+15); k=k+1)begin
            @(negedge clk) ;
            input_task ;
            $display("test%d", k) ;
        end
        @(negedge clk) ;
        in_valid = 0 ;
        #(40*CYCLE) ;
        $finish ;
    end
    
    task input_task ;
    begin
        read = $fscanf(input_file, "%d", input_data) ;
        in_data = input_data ;
    end
    endtask

endmodule
