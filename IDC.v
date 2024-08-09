`timescale 1ns / 1ps
module IDC(
input clk, rstn, in_valid,
input signed [6:0] in_data,
//input [3:0] op,
output reg out_valid,
output reg signed [6:0] out_data
    );
    
    parameter IDLE = 2'b00 ;
    parameter READ_INPUT = 2'b01 ;
    parameter PROCESS = 2'b10 ;
    parameter OUT_MAP = 2'b11 ;
    reg signed [6:0] in_data_reg ;
    
    reg [1:0] cs, ns ;
    
    reg [3:0] operation [0:14] ;
    reg signed [6:0] map [0:7][0:7] ;
    
    reg [7:0] cnt_read_input ; // [5:3] for raw, [2:0] for column
    reg [3:0] cnt_process ;
    reg [3:0] cnt_output ;
    
    reg [2:0] point_x ;
    reg [2:0] point_y ;
    
    //==============
    //state
    //==============
    
    always@(posedge clk)begin
        if(!rstn) in_data_reg = 0 ;
        else begin
            if(cs == IDLE || cs == READ_INPUT) in_data_reg = in_data ;
            else in_data_reg = 0 ;
        end
    end
    
    always@(*)begin
        case(cs)
            IDLE:begin
                if(in_valid) ns = READ_INPUT ;
                else ns = IDLE ;
            end
            READ_INPUT:begin
                if(cnt_read_input == (63+15)) ns = PROCESS ;
                else ns = READ_INPUT ;
            end
            PROCESS:begin
                if(cnt_process == 14) ns = OUT_MAP ;
                else ns = PROCESS ;
            end
            OUT_MAP:begin
                if(cnt_output == 15) ns = IDLE ;
                else ns = OUT_MAP ;
            end
        endcase
    end
    
    always@(posedge clk)begin
        if(!rstn) cs <= IDLE ;
        else cs <= ns ;
    end
    
    //==============
    // cnt
    //==============
    always@(posedge clk)begin
        if(!rstn) cnt_read_input <= 0 ;
        else begin
            if(cs == READ_INPUT && in_valid == 1) cnt_read_input <= cnt_read_input + 1 ;
            else cnt_read_input <= 0 ;
        end
    end
    
    always@(posedge clk)begin
        if(!rstn) cnt_process <= 0 ;
        else begin
            if(cs == PROCESS) cnt_process <= cnt_process + 1 ;
            else cnt_process <= 0 ;
        end
    end
    
    always@(posedge clk)begin
        if(!rstn) cnt_output <= 0 ;
        else begin
            if(cs == OUT_MAP && out_valid == 1) cnt_output <= cnt_output + 1 ;
            else cnt_output <= 0 ;
        end
    end
    
    //==============
    // map read and operation
    //==============    
    //op0
    reg [6:0] op0 ;
    always@(*)begin
        if(map[point_y][point_x] >= map[point_y+1][point_x])begin
            if(map[point_y][point_x+1] >= map[point_y+1][point_x+1]) op0 = (map[point_y+1][point_x] + map[point_y+1][point_x+1])/2 ;
            else if(map[point_y][point_x+1] < map[point_y+1][point_x+1]) op0=  (map[point_y+1][point_x] + map[point_y][point_x+1])/2 ;
            else op0 = 0 ;
        end
        else if(map[point_y][point_x] < map[point_y+1][point_x])begin
            if(map[point_y][point_x+1] >= map[point_y+1][point_x+1]) op0 = (map[point_y][point_x] + map[point_y+1][point_x+1])/2 ;
            else if(map[point_y][point_x+1] < map[point_y+1][point_x+1]) op0=  (map[point_y][point_x] + map[point_y][point_x+1])/2 ;
            else op0 = 0 ;
        end
        else op0 = 0 ;
    end
    //op1
    reg [6:0] op1 ;
    always@(*)begin
        op1 = (map[point_y][point_x] + map[point_y+1][point_x] + map[point_y][point_x+1] + map[point_y+1][point_x+1])/4 ;
    end
    
    integer i, j ;
    always@(posedge clk)begin
        if(!rstn) begin
            for(i=0; i<8; i=i+1)begin
                for(j=0; j<8; j=j+1)begin
                    map[i][j] <= 0 ;
                end
            end
        end
        else begin
            case(cs)
                READ_INPUT:begin
                    if(in_valid == 1 && cnt_read_input<64) map[cnt_read_input[5:3]][cnt_read_input[2:0]] <= in_data_reg ;
                    else map[cnt_read_input[5:3]][cnt_read_input[2:0]] <= map[cnt_read_input[5:3]][cnt_read_input[2:0]] ;
                end
                PROCESS:begin
                    case(operation[cnt_process])
                        4'd0:begin
                            map[point_y]    [point_x]   <= op0 ;
                            map[point_y+1]  [point_x]   <= op0 ;
                            map[point_y]    [point_x+1] <= op0 ;
                            map[point_y+1]  [point_x+1] <= op0 ;
                        end
                        4'd1:begin
                            map[point_y]    [point_x]   <= op1 ;
                            map[point_y+1]  [point_x]   <= op1 ;
                            map[point_y]    [point_x+1] <= op1 ;
                            map[point_y+1]  [point_x+1] <= op1 ;
                        end
                        4'd3:begin
                            map[point_y]    [point_x]   <= map[point_y+1]   [point_x] ;
                            map[point_y+1]  [point_x]   <= map[point_y+1]   [point_x+1] ;
                            map[point_y]    [point_x+1] <= map[point_y]     [point_x] ;
                            map[point_y+1]  [point_x+1] <= map[point_y]     [point_x+1] ;
                        end
                        4'd2:begin
                            map[point_y]    [point_x]   <= map[point_y]     [point_x+1] ;
                            map[point_y+1]  [point_x]   <= map[point_y]     [point_x] ;
                            map[point_y]    [point_x+1] <= map[point_y+1]   [point_x+1] ;
                            map[point_y+1]  [point_x+1] <= map[point_y+1]   [point_x] ;
                        end
                        4'd4:begin
                            map[point_y]    [point_x]   <= -map[point_y]    [point_x] ;
                            map[point_y+1]  [point_x]   <= -map[point_y+1]  [point_x] ;
                            map[point_y]    [point_x+1] <= -map[point_y]    [point_x+1] ;
                            map[point_y+1]  [point_x+1] <= -map[point_y+1]  [point_x+1] ;
                        end
                        default:map[point_y][point_x] <= map[point_y][point_x] ;
                    endcase
                end
                default: map[cnt_read_input[5:3]][cnt_read_input[2:0]] <= map[cnt_read_input[5:3]][cnt_read_input[2:0]];
            endcase
        end
    end
    
    //==============
    // op
    //==============
    always@(posedge clk)begin
        if(!rstn) begin
            for(i=0; i<15; i=i+1)begin
                operation[i] <= 0 ;
            end
        end
        else begin
            case(cs)
                READ_INPUT:begin
                    if(in_valid == 1 && cnt_read_input > 63) operation[cnt_read_input-64] <= in_data_reg ;
                    else operation[cnt_read_input-64] <= operation[cnt_read_input-64] ;
                end
            endcase
        end
    end
    
    //==============
    // op point x & y
    //==============
    always@(posedge clk)begin
        if(!rstn) begin
            point_x <= 3 ;
            point_y <= 3 ;
        end
        else begin
            case(cs)
                PROCESS:begin
                    if(operation[cnt_process] == 5)begin
                        if(point_y == 0) point_y <= point_y ;
                        else point_y <= point_y - 1 ;
                    end
                    else if(operation[cnt_process] == 6)begin
                        if(point_x == 0) point_x <= point_x ;
                        else point_x <= point_x - 1 ;
                    end
                    else if(operation[cnt_process] == 7)begin
                        if(point_y == 6) point_y <= point_y ;
                        else point_y <= point_y + 1 ;
                    end
                    else if(operation[cnt_process] == 8)begin
                        if(point_x == 6) point_x <= point_x ;
                        else point_x <= point_x + 1 ;
                    end
                    else begin
                        point_x <= point_x ;
                        point_y <= point_y ;
                    end
                end
                default:begin
                    point_x <= point_x ;
                    point_y <= point_y ;
                end
            endcase
        end
    end
    
    //==============
    // output
    //==============
    always@(posedge clk)begin
        if(!rstn) out_valid <= 0 ;
        else begin
            if(cs == OUT_MAP) out_valid <= 1 ;
            else out_valid <= 0 ;
        end
    end
    
    always@(posedge clk)begin
        if(!rstn) out_data <= 0 ;
        else begin
            if(cs == OUT_MAP && out_valid == 1)begin
                if(point_x >= 4 || point_y >= 4)begin
                    out_data <= map[2*cnt_output[3:2]][2*cnt_output[1:0]] ;
                end
                else if(point_x < 4 || point_y <4)begin
                    out_data <= map[point_y + cnt_output[3:2]][point_x + cnt_output[1:0]] ;
                end
                else out_data <= 0 ;
            end
            else out_data <= 0 ;
        end
    end
endmodule