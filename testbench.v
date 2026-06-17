
module testbench;
  reg cs, rd_en, clk;
  reg [4:0] addr1, addr2, addr3, addr4;
  wire [7:0] data1, data2, data3, data4;


  ROM dut (
        .clk(clk),
        .rd_en (rd_en),
        .cs (cs),
        .address_vector({addr1,addr2,addr3,addr4}),
        .data_vector({data1,data2,data3,data4})
        // .addr2(addr2),
        // .data2(data2)
      );

  localparam CLK_PERIOD = 10;
  always #(CLK_PERIOD/2) clk = ~clk;

  //dumping the variables
  initial
  begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, testbench);
  end

  //initial values
  initial
  begin
    clk = 1'b0;
    cs = 1'b1;
    rd_en = 1'b0;
    addr1 = 5'b0;
    addr2 = 5'b0;
    addr3 = 5'b0;
    addr4 = 5'b0;
  end

  initial
  begin
    $monitor("%0t\t%b\t%b\t%b\t%h\t%b\t%h\t%b\t%h\t%b\t%h", $time, cs, rd_en, addr1, data1, addr2, data2, addr3, data3, addr4, data4);

    #10 rd_en = 1'b1;

    #10 addr1 = 5'b01000;
    addr2 = 5'b10001;
    addr3 = 5'b01100;
    addr4 = 5'b00110;

    #10 addr1 = 5'b00101;
    addr2 = 5'b00011;
    addr3 = 5'b00101;
    addr4 = 5'b00111;

    #10 addr1 = 5'b00001;
    addr2 = 5'b11111;
    addr3 = 5'b10001;
    addr4 = 5'b01100;

    #10 addr1 = 5'b11011;
    addr2 = 5'b01000;
    addr3 = 5'b01011;
    addr4 = 5'b10010;


    #20 $finish;
  end
endmodule
