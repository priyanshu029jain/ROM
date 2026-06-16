
module single_port_ROM(
    input [2:0] addr,
    input rd_en, cs,
    output reg [7:0] data
);
    
    always @(*) begin
        // The ROM only outputs data if the chip is selected AND read is enabled
        if ({cs, rd_en} == 2'b11) begin
            case (addr) 
                3'b000 : data = 8'hA5; 
                3'b001 : data = 8'h12;
                3'b010 : data = 8'hFF;
                3'b011 : data = 8'h00;
                3'b100 : data = 8'h55;
                3'b101 : data = 8'hC3;
                3'b110 : data = 8'h3B;
                3'b111 : data = 8'h7E;
                default : data = 8'h00;
            endcase
        end else begin
            data = 8'h00; 
        end
    end
    
endmodule