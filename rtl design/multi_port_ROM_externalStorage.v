
module ROM #(
    parameter data_width = 8,
    parameter memory_size = 8,
    parameter ports = 4,
    parameter file_path = "external_storage.mem"
  ) (
    input clk, cs, rd_en,
    input [addr_bites -1:0] addr,// one addr_vector containg the addr of all ports
    output reg [data_bites -1:0] data // contain the data coming out of all ports
  );

  localparam addr_width = $clog2(memory_size);
  localparam addr_bites = ports * addr_width;
  localparam data_bites = ports * data_width;

  //declearing the memort array
  reg [data_width -1:0] mem_array [0:memory_size -1];

  //initializing the values stored in rom from external files "rom.mem"
  initial
  begin
    $readmemh(file_path, mem_array, 0 ,memory_size -1);
  end

  integer i;
  always @(posedge clk)
  begin

    if ({cs, rd_en} == 2'b11)
    begin

      for( i = 0; i < ports; i = i + 1)
      begin
        data[i*data_width +: data_width] <= mem_array[addr[i*addr_width +: addr_width]];
      end

    end

    else
    begin
      data <= {data_bites{1'b0}};
    end
  end

endmodule
