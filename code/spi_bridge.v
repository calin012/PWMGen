// spi_bridge.v
// Simple SPI slave (MSB first, CPOL=0 CPHA=0).
// Produces byte_sync and data_in on each received byte, provides data_out -> MISO.

module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,
    output reg miso,
    // internal facing 
    output reg byte_sync,
    output reg [7:0] data_in,
    input  [7:0] data_out
);

    // shift registers synchronized to peripheral clock
    reg [7:0] shift_in;
    reg [7:0] shift_out;
    reg [2:0] bitcnt;
    reg prev_sclk;
    reg active;

    // We sample MOSI on rising edge of SCLK (CPOL=0, CPHA=0),
    // and change MISO on falling edge so master samples it properly.

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sclk <= 1'b0;
            bitcnt <= 3'd7;
            shift_in <= 8'h00;
            shift_out <= 8'h00;
            byte_sync <= 1'b0;
            data_in <= 8'h00;
            miso <= 1'b0;
            active <= 1'b0;
        end else begin
            byte_sync <= 1'b0; // pulse for one clk when a full byte received

            // detect cs_n active low (slave selected)
            if (!cs_n) begin
                if (!active) begin
                    // became active: initialize counters and preload shift_out with data_out (to be shifted out MSB first)
                    active <= 1'b1;
                    shift_out <= data_out;
                    bitcnt <= 3'd7;
                    miso <= data_out[7]; // present MSB first
                end

                // edge detection of sclk
                if (prev_sclk == 1'b0 && sclk == 1'b1) begin
                    // rising edge
                    shift_in[bitcnt] <= mosi;
                    if (bitcnt == 3'd0) begin
                        // finished receiving a byte
                        data_in <= {shift_in[7:1], mosi}; 
                        byte_sync <= 1'b1;
                        bitcnt <= 3'd7;
                        // reload shift_out with latest data_out so MISO will output its MSB next
                        shift_out <= data_out;
                        miso <= data_out[7];
                    end else begin
                        bitcnt <= bitcnt - 1'b1;
                    end
                end

                // put next bit on MISO on falling edge
                if (prev_sclk == 1'b1 && sclk == 1'b0) begin
                    // shift shift_out left to present next bit
                    shift_out <= {shift_out[6:0], 1'b0};
                    miso <= shift_out[6];
                end
            end else begin
                // cs_n inactive -> reset state
                active <= 1'b0;
                bitcnt <= 3'd7;
                shift_in <= 8'h00;
                shift_out <= data_out;
                miso <= data_out[7];
            end

            prev_sclk <= sclk;
        end
    end

endmodule
