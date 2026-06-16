
module multi_port_ROM #(
    parameter data_width = 8,
    parameter memory_size = 8,
    parameter ports = 4
  ) (
    input clk, cs, rd_en,
    input [addr_bites -1:0] addr,// one addr_vector containg the addr of all ports
    output reg [data_bites -1:0] data // contain the data coming out of all ports
  );

  localparam addr_width = $clog2(memory_size);
  localparam addr_bites = ports * addr_width;
  localparam data_bites = ports * data_width;

  
  integer i;
  always @(*)
  begin
    if ({cs, rd_en} == 2'b11)
    begin
      for( i = 0; i < ports; i = i + 1)
      begin
        case (addr[i*addr_width +: addr_width])
          3'b000 :
            data[i*data_width +: data_width] = 8'hA5;
          3'b001 :
            data[i*data_width +: data_width] = 8'h12;
          3'b010 :
            data[i*data_width +: data_width] = 8'hFF;
          3'b011 :
            data[i*data_width +: data_width] = 8'h00;
          3'b100 :
            data[i*data_width +: data_width] = 8'h55;
          3'b101 :
            data[i*data_width +: data_width] = 8'hC3;
          3'b110 :
            data[i*data_width +: data_width] = 8'h3B;
          3'b111 :
            data[i*data_width +: data_width] = 8'h7E;
          default :
            data[i*data_width +: data_width] = 8'h00;
        endcase
      end
    end
    else
    begin
      data = {data_bites{1'b0}};
    end
  end

endmodule
