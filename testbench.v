
module testbench;
  reg cs, rd_en;
  reg [2:0] addr1, addr2, addr3, addr4;
  wire [7:0] data1, data2, data3, data4;


  ROM dut (
        .rd_en (rd_en),
        .cs (cs),
        .addr({addr1,addr2,addr3,addr4}),
        .data({data1,data2,data3,data4})
        // .addr2(addr2),
        // .data2(data2)
      );

  // localparam CLK_PERIOD = 10;
  // always #(CLK_PERIOD/2) clk=~clk;

  //dumping the variables
  initial
  begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, testbench);
  end

  //initial values
  initial
  begin
    cs = 1'b1;
    rd_en = 1'b0;
    addr1 = 3'b000;
    addr2 = 3'b000;
    addr3 = 3'b000;
    addr4 = 3'b000;
  end

  initial
  begin
    $monitor("%0t\t%b\t%b\t%b\t%h\t%b\t%h\t%b\t%h\t%b\t%h", $time, cs, rd_en, addr1, data1, addr2, data2, addr3, data3, addr4, data4);

    #10 rd_en = 1'b1;

    #10 addr1 = 3'b010;
    addr2 = 3'b100;
    addr3 = 3'b011;
    addr4 = 3'b001;

    #10 addr1 = 3'b101;
    addr2 = 3'b011;
    addr3 = 3'b001;
    addr4 = 3'b111;

    #10 addr1 = 3'b001;
    addr2 = 3'b111;
    addr3 = 3'b100;
    addr4 = 3'b011;

    #10 addr1 = 3'b110;
    addr2 = 3'b010;
    addr3 = 3'b010;
    addr4 = 3'b100;

    #20 $finish;
  end
endmodule
