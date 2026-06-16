
module testbench;
reg cs, rd_en;
reg [2:0] addr;
wire [7:0] data;

 
ROM dut (
    .rd_en (rd_en),
    .cs (cs),
    .addr(addr),
    .data(data)
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
    addr = 3'b000;
end

initial begin
    $monitor("%0t\t%b\t%b\t%0b\t%h", $time, cs, rd_en, addr, data);  

    #10 rd_en = 1'b1;
    #10 addr = 3'b010;
    #10 addr = 3'b101;
    #10 addr = 3'b001;
    #10 addr = 3'b110;
    #20 $finish;
end
endmodule
