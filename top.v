module top(
    input  clk,
    input  rst_n,

    input  sclk,
    input  cs_n,
    input  miso,     // TB naming: master->slave data
    output mosi,     // TB naming: slave->master data

    output pwm_out
);

    // raw SPI byte interface
    wire       byte_sync_w;
    wire [7:0] data_in_w;
    wire [7:0] data_out;

    // pipelined into clk domain (1-cycle later, stable)
    reg        byte_sync;
    reg  [7:0] data_in;

    // register interface
    wire       read, write;
    wire [5:0] addr;
    wire [7:0] data_read, data_write;

    // counter / pwm signals
    wire [15:0] counter_val;
    wire [15:0] period;
    wire        en, count_reset, upnotdown;
    wire [7:0]  prescale;
    wire        pwm_en;
    wire [7:0]  functions;
    wire [15:0] compare1, compare2;

    spi_bridge i_spi_bridge (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(miso),
        .miso(mosi),
        .byte_sync(byte_sync_w),
        .data_in(data_in_w),
        .data_out(data_out)
    );

    // pipeline byte_sync + data_in so downstream logic sees them cleanly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_sync <= 1'b0;
            data_in   <= 8'h00;
        end else begin
            byte_sync <= byte_sync_w;
            if (byte_sync_w)
                data_in <= data_in_w;
        end
    end

    instr_dcd i_instr_dcd (
        .clk(clk),
        .rst_n(rst_n),
        .byte_sync(byte_sync),
        .data_in(data_in),
        .data_out(data_out),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write)
    );

    regs i_regs (
        .clk(clk),
        .rst_n(rst_n),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write),
        .counter_val(counter_val),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale),
        .pwm_en(pwm_en),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2)
    );

    counter i_counter (
        .clk(clk),
        .rst_n(rst_n),
        .count_val(counter_val),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale)
    );

    pwm_gen i_pwm_gen (
        .clk(clk),
        .rst_n(rst_n),
        .pwm_en(pwm_en),
        .period(period),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2),
        .count_val(counter_val),
        .pwm_out(pwm_out)
    );

endmodule
