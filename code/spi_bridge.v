// spi_bridge.v
// SPI slave: MSB first, CPOL=0, CPHA=0
// Shifts on sclk edges (robust even if sclk ~= clk).
module spi_bridge (
    // peripheral clock domain
    input  wire       clk,
    input  wire       rst_n,

    // SPI pins (master-facing)
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi,
    output reg        miso,

    // internal interface (clk domain)
    output reg        byte_sync,   // 1 clk pulse when a byte received
    output reg [7:0]  data_in,     // received byte (clk domain)
    input  wire [7:0] data_out     // byte to transmit (clk domain)
);

    // sclk domain shifters
    reg [7:0] shift_in_s;
    reg [7:0] shift_out_s;
    reg [2:0] bitcnt_s;

    // completed-byte buffer in sclk domain
    reg [7:0] byte_buf_s;

    // toggle when a full byte is received (sclk domain)
    reg byte_toggle_s;

    // load a new outgoing byte at start of each 8-bit frame
    // CPHA=0: output MSB before first rising edge
    always @(negedge cs_n or posedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            shift_out_s   <= 8'h00;
            miso          <= 1'b0;
            bitcnt_s      <= 3'd7;
            shift_in_s    <= 8'h00;
            byte_buf_s    <= 8'h00;
            byte_toggle_s <= 1'b0;
        end else if (cs_n) begin
            // deselect
            bitcnt_s <= 3'd7;
            // keep miso stable
        end else begin
           // prepare first bit
            bitcnt_s    <= 3'd7;
            shift_out_s <= data_out;     // async sample is OK for this TB
            miso        <= data_out[7];  // present MSB immediately
        end
    end

    // sample MOSI on rising edge (CPHA=0)
    always @(posedge sclk or posedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            shift_in_s    <= 8'h00;
            bitcnt_s      <= 3'd7;
            byte_buf_s    <= 8'h00;
            byte_toggle_s <= 1'b0;
        end else if (cs_n) begin
            bitcnt_s <= 3'd7;
        end else begin
            shift_in_s[bitcnt_s] <= mosi;

            if (bitcnt_s == 3'd0) begin
                // byte complete
                byte_buf_s    <= {shift_in_s[7:1], mosi};
                byte_toggle_s <= ~byte_toggle_s;

                // start next byte immediately
                bitcnt_s      <= 3'd7;
                shift_out_s   <= data_out;    // sample next response byte
                miso          <= data_out[7];
            end else begin
                bitcnt_s <= bitcnt_s - 3'd1;
            end
        end
    end

    // shift MISO on falling edge so itss stable before next rising edge sample
    always @(negedge sclk or posedge cs_n or negedge rst_n) begin
        if (!rst_n) begin
            shift_out_s <= 8'h00;
            miso        <= 1'b0;
        end else if (cs_n) begin
            // do nothing
        end else begin
            shift_out_s <= {shift_out_s[6:0], 1'b0};
            miso        <= shift_out_s[6];
        end
    end

    // clk domain: synchronize toggle
    reg toggle_ff1, toggle_ff2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_ff1 <= 1'b0;
            toggle_ff2 <= 1'b0;
            byte_sync  <= 1'b0;
            data_in    <= 8'h00;
        end else begin
            toggle_ff1 <= byte_toggle_s;
            toggle_ff2 <= toggle_ff1;

            // pulse when toggle changes
            byte_sync <= (toggle_ff2 ^ toggle_ff1);

            if (toggle_ff2 ^ toggle_ff1) begin
                // capture the completed byte
                data_in <= byte_buf_s;
            end
        end
    end

endmodule
