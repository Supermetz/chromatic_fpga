// polling_master.v
// Poll TLV320 Audio codec
/// Read volume wheel value (Page0 R117 bits 6:0)
/// Read GPIO (headphone attached) value(Page0 R51 bit1)
//// Toggle headphone or speaker

// Poll BQ24296MRGER PMIC state
/// I2C address 0x6B
/// Write R02 = 10111100 is 0xBC (3008mA)
/// Read  R08 System Status Reg
/// Read  R09 New Fault Register

// Poll ATSHA204A encryption

module polling_master#(
    parameter I2C_DATA_WIDTH = 8,
    parameter REGISTER_WIDTH = 8,
    parameter ADDRESS_WIDTH = 7
)(
    input                                   clk,
    input                                   rst,
    input                                   i2c_busy,
    input                                   enable,
    input                                   mute,
    
    input           [7:0]                   i2c_miso_data,

    output  reg [7:0]                       volume,
    output  reg [7:0]                       gpio,
    output  reg [7:0]                       pmic_sys_status,
    output  reg [7:0]                       new_fault,
    output  reg [7:0]                       inlim,
    
    output  reg                             i2c_enable,
    output  reg                             i2c_read_write,
    output  reg     [I2C_DATA_WIDTH-1:0]    i2c_mosi_data,
    output  reg     [REGISTER_WIDTH-1:0]    i2c_register_address,
    output  reg     [ADDRESS_WIDTH-1:0]     i2c_device_address
    
);

    reg [7:0] scount;
    reg [7:0] regindex;
    
    localparam CODEC = 7'h18;
    localparam PMIC = 7'h6B;
    
    reg [11:0] state;
    localparam S_VOLUME = 12'd1;
    localparam S_HP_GPIO = 12'd2;
    localparam S_HP_EN0 = 12'd4;
    localparam S_HP_EN1 = 12'd8;
    localparam S_HP_SWPWRDOWN = 12'd16;
    localparam S_HP_EN2 = 12'd32;
    localparam S_HP_EN3 = 12'd64;
    localparam S_HP_EN4 = 12'd128;
    localparam S_SYS_STATUS = 12'd256;
    localparam S_NEW_FAULT = 12'd512;
    localparam S_INLIM = 12'd1024;
    localparam S_IDLE = 12'd2048;

    reg txActive;

    always@(posedge clk)
    begin
        if(rst)
        begin
            scount               <= 'd0;
            i2c_read_write       <= 'd0;
            i2c_register_address <= 'd0;
            i2c_mosi_data        <= 'd0;
            i2c_device_address   <= CODEC;
            i2c_enable           <= 'd0;
            regindex             <= 'd0;
            state                <= S_IDLE;
        end
        else
            case(state)
            S_IDLE:
            begin
                i2c_enable       <= 'd0;
                txActive         <= 1'd0;
                i2c_read_write   <= 'd1; // Read
                if(~i2c_busy && enable)
                begin
                    state                <= S_VOLUME;
                    i2c_device_address   <= CODEC;
                    i2c_register_address <= 8'd117; // Volume
                end
            end
            S_VOLUME:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        i2c_read_write   <= 'd1; // Read
                        state                <= S_HP_GPIO;
                        i2c_register_address <= 8'd51; // HP Status
                        i2c_device_address   <= CODEC;
                        volume               <= i2c_miso_data;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable       <= 'd1;
            end
            S_HP_GPIO:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        gpio                 <= i2c_miso_data;
                        state                <= S_HP_EN0;
                        i2c_read_write       <= 'd0; // Write
                        i2c_register_address <= 8'd00; // Page select
                        i2c_mosi_data        <= 8'd01; // Page 1
                        i2c_device_address   <= CODEC;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
            S_HP_EN0:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        state                <= S_HP_EN1;
                        i2c_read_write       <= 'd0; // Write
                        i2c_register_address <= 8'h26; // Left Analog Volume to SPK
                        if(gpio[1])
                            i2c_mosi_data        <= 8'h7F; // Mute Speaker (use headphones)
                        else
                            i2c_mosi_data        <= 8'h00; // Enable speaker (use speaker)
                        i2c_device_address   <= CODEC;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
             S_HP_EN1:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        state                <= S_HP_SWPWRDOWN;
                        i2c_read_write       <= 'd0; // Write
                        i2c_register_address <= 8'h1F; // Headphone Driver
                        if(gpio[1])
                            i2c_mosi_data        <= 8'hC4; // Enable driver (use headphones)
                        else
                            i2c_mosi_data        <= 8'h04; // 04 Disable driver (use speaker)

                        i2c_device_address   <= CODEC;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
             S_HP_SWPWRDOWN:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        state                <= S_HP_EN2;
                        i2c_read_write       <= 'd0; // Write
                        i2c_register_address <= 8'h2E; // Headphone Driver
                        if(mute)
                            i2c_mosi_data        <= 8'h80; // software power down - enabled
                        else
                            i2c_mosi_data        <= 8'h00; // software power down - disabled

                        i2c_device_address   <= CODEC;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
             S_HP_EN2:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        state                <= S_HP_EN3;
                        i2c_read_write       <= 'd0; // Write
                        i2c_register_address <= 8'd00; // Page select
                        i2c_mosi_data        <= 8'd00; // Page 0
                        i2c_device_address   <= CODEC;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
            S_HP_EN3:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        state                <= S_HP_EN4;
                        i2c_read_write       <= 'd0; // Write
                        i2c_register_address <= 8'h3F; // DAC Data-Path setup
                        if(gpio[1])
                            i2c_mosi_data        <= 8'hD4; // Power up both dacs
                        else
                            i2c_mosi_data        <= 8'h90; // Power down right DAC, speaker mix both channel
                        i2c_device_address   <= CODEC;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
            S_HP_EN4:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        i2c_read_write       <= 'd1; // Read
                        state                <= S_SYS_STATUS;
                        i2c_register_address <= 8'd08; // System Status
                        i2c_device_address   <= PMIC;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
            S_SYS_STATUS:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        i2c_read_write       <= 'd1; // Read
                        state                <= S_NEW_FAULT;
                        i2c_register_address <= 8'd09; // Fault Status
                        i2c_device_address   <= PMIC;
                        pmic_sys_status      <= i2c_miso_data;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
            S_NEW_FAULT:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        i2c_read_write       <= 'd1; // Read
                        state                <= S_INLIM;
                        i2c_register_address <= 8'd00; // Input Limit
                        i2c_device_address   <= PMIC;
                        new_fault            <= i2c_miso_data;
                        txActive             <= 1'd0;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
            S_INLIM:
            begin
                if(i2c_busy)
                begin
                    txActive         <= 1'd1;
                    i2c_enable       <= 'd0;
                end
                else
                    if(txActive)
                    begin
                        state                <= S_IDLE;
                        txActive             <= 1'd0;
                        inlim                <= i2c_miso_data;
                    end
                    else
                        i2c_enable           <= 'd1;
            end
            endcase
    end

endmodule