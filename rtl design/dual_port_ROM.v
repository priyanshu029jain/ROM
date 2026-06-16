module dual_port_ROM(
    input [2:0] addr1,addr2, //read address
    input rd_en, cs, //chip select and read enable
    output reg [7:0] data1,data2 //output data
);

   // 1st port
    always @(*) begin
        if ({cs, rd_en} == 2'b11) begin
            case (addr1) 
                3'b000 : data1 = 8'hA5; 
                3'b001 : data1 = 8'h12;
                3'b010 : data1 = 8'hFF;
                3'b011 : data1 = 8'h00;
                3'b100 : data1 = 8'h55;
                3'b101 : data1 = 8'hC3;
                3'b110 : data1 = 8'h3B;
                3'b111 : data1 = 8'h7E;
                default : data1 = 8'h00;
            endcase
        end else begin
            data1 = 8'h00; 
        end
    end
  
  //2nd port 
    always @(*) begin
        if ({cs, rd_en} == 2'b11) begin
            case (addr2) 
                3'b000 : data2 = 8'hA5; 
                3'b001 : data2 = 8'h12;
                3'b010 : data2 = 8'hFF;
                3'b011 : data2 = 8'h00;
                3'b100 : data2 = 8'h55;
                3'b101 : data2 = 8'hC3;
                3'b110 : data2 = 8'h3B;
                3'b111 : data2 = 8'h7E;
                default : data2 = 8'h00;
            endcase
        end else begin
            data2 = 8'h00; 
        end
    end 
     
endmodule