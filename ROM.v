
`define BYTE 8
`define FILE "external_storage.mem"

module ROM #(
    parameter WORD_SIZE = 1, //bytes in word
    parameter BLOCK_SIZE = 4, //no. of words per block
    parameter RAM_BLOCKS = 8, //no of block in RAM memory
    parameter PORTS = 4 // no of ports
  ) (
    input wire clk, // clock signal
    input wire [PORTS -1: 0] rd, // read enable signal for all ports
    input wire cs, //chip select
    input wire rst_n,//reset signal
    input wire [address_vector_width -1:0] address_vector, // 5 bit address

    output reg ready,
    output reg [data_vector_width -1:0] data_vector // 8 bit data output
  );

  // Calculate the number of bits for various components based on the parameters
  localparam word_width = WORD_SIZE * `BYTE; // Number of bits in a word
  localparam block_width = BLOCK_SIZE * word_width; // Number of bits in a block
  localparam address_width = $clog2(RAM_BLOCKS * BLOCK_SIZE); // Number of bits in the address
  localparam data_width = word_width; // Number of bits in the data bus
  localparam address_vector_width = PORTS * address_width; //number of bites in address vector
  localparam data_vector_width = PORTS * data_width; //number of bites in data vector

  // Calculate the number of bits for the tag and offset based on the address breakdown
  localparam offset_width = $clog2(BLOCK_SIZE); // Number of bits for the word offset within a block
  localparam block_no_width = $clog2(RAM_BLOCKS); // number of bites for the block address in RAM

  //states of ROM controller FSM
  localparam idle_state = 2'b00, 
             fetch_state = 2'b01,
             read_state = 2'b10;

  reg [1:0] current_state, next_state;

  //declearing the memory array
  reg [block_width -1:0] mem_array [0:RAM_BLOCKS -1];

  /// Initialize ROM from external storage
  initial
  begin
    $readmemh(`FILE, mem_array, 0 ,RAM_BLOCKS -1);
  end

  //function for data reading form a block
  function [data_width-1:0] d_out;
    input [address_width-1:0] addr;
    input read;
    //declareing the RAM block, block number, block offset
    reg [block_width-1:0]    block;
    reg [block_no_width-1:0] block_no;
    reg [offset_width-1:0]   block_offset;
    begin
      if(read) begin
      // derive block number and offset
      block_no     = addr[address_width-1 : offset_width];
      block_offset = addr[offset_width-1 : 0];

      // fetch block from memory
      block = mem_array[block_no];

      // slice out the word
      d_out = block[block_offset * data_width +: data_width];
      end 
      else d_out = {data_width{1'bz}};
    end
  endfunction

  //FSM sequential logic
  always @(posedge clk)
  begin
    if(rst_n)
      current_state <= idle_state;
    else
      current_state <= next_state;
  end

  //FSM Combinational logic
  integer i;
  always @(*)
  begin
    //passing the default values
    data_vector = {data_vector_width{1'b0}};
    ready = 1'b0;
    next_state = current_state;

    case(current_state)
      idle_state :
      begin
        if( |rd && cs)
          next_state = fetch_state; // Request accepted, jump to fetch
      end

      fetch_state :
      begin
        //Its purpose is to deliberately delay your hardware control pipeline by one or more clock cycles 
        //to match the physical access latency of the memory cell array
        next_state = read_state; 
      end

      read_state :
      begin
        for (i = 0; i < PORTS; i = i + 1)
        begin
          data_vector[i*data_width +: data_width] <= d_out(address_vector[i*address_width +: address_width], rd[i]); //drevie data out from all ports 
        end

        next_state = ( |rd && cs) ? fetch_state : idle_state; // Pipeline directly into the next read or standby mode
        ready = 1'b1; // signal cpu/master that data is ready
      end
      default :
        next_state = idle_state;
    endcase
  end


endmodule

