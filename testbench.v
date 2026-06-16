
module testbench;
reg cs, rd_en;
reg [2:0] addr1, addr2;
wire [7:0] data1, data2;

 
ROM dut (
    .rd_en (rd_en),
    .cs (cs),
    .addr1(addr1),
    .data1(data1),
    .addr2(addr2),
    .data2(data2)
);

// localparam CLK_PERIOD = 10;
// always #(CLK_PERIOD/2) clk=~clk;

//dumping the variables
initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, testbench);
end

//initial values
initial begin
    cs = 1'b1;
    rd_en = 1'b0;
    addr1 = 3'b000;
    addr2 = 3'b000;
end

initial begin
    $monitor("%0t\t%b\t%b\t%b\t%h\t%b\t%h", $time, cs, rd_en, addr1, data1, addr2, data2);  

    #10 rd_en = 1'b1;
    #10 addr1 = 3'b010; addr2 = 3'b100;
    #10 addr1 = 3'b101; addr2 = 3'b011;
    #10 addr1 = 3'b001; addr2 = 3'b111;
    #10 addr1 = 3'b110; addr2 = 3'b010;
    #20 $finish;
end
endmodule
