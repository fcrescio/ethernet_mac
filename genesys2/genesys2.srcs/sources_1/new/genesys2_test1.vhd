----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/21/2017 04:25:40 PM
-- Design Name: 
-- Module Name: genesys2_test1 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.ethernet_types.all;
use work.miim_types.all;


entity genesys2_test1 is
    Port ( 
        sysclk_n : in STD_ULOGIC;
        sysclk_p : in std_ulogic;
        
        -- RGMII (Reduced pin count gigabit media-independent interface)
        rgmii_rxd         : in std_ulogic_vector(3 downto 0);
        rgmii_rxctl       : in std_ulogic;
        rgmii_rxc         : in std_ulogic;
        rgmii_txd         : out std_ulogic_vector(3 downto 0);
        rgmii_txctl       : out std_ulogic;
        rgmii_txc         : out std_ulogic;

        -- MII Management Interface
        -- Clock, can be identical to clock_125_i
        -- If not, adjust MIIM_CLOCK_DIVIDER accordingly
        mdc_o            : out   std_ulogic;
        mdio_io          : inout std_ulogic;
        -- Status, synchronous to miim_clock_i

        -- user IO
        reset_n         : in std_ulogic;
        txbtn           : in std_ulogic;
        led             : out std_ulogic_vector(7 downto 0);
        sw              : in std_ulogic_vector(1 downto 0);
        -- fan control
        fan_en : out std_ulogic
    );
end genesys2_test1;

architecture Behavioral of genesys2_test1 is
    signal clock_125 : std_ulogic;
    signal int_reset : std_ulogic;
    
    signal int_clock : std_ulogic;
    
    signal sysclk : std_ulogic;
    
    signal feedback_clock: std_ulogic;
    
    signal link_up_o : std_ulogic;
    signal speed_o : std_ulogic_vector(1 downto 0);
    
    signal datarx : std_ulogic_vector(7 downto 0);
begin

    fan_en <= '0';
    
    led <=  "000000" & speed_o when sw = "00" else
            "0000000" & link_up_o when sw = "01" else
            datarx;

       sysclk_inst : IBUFDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "DEFAULT")
   port map (
      O => sysclk,  -- Buffer output
      I => sysclk_p,  -- Diff_p buffer input (connect directly to top-level port)
      IB => sysclk_n -- Diff_n buffer input (connect directly to top-level port)
   );


   PLLE2_BASE_inst : PLLE2_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",  -- OPTIMIZED, HIGH, LOW
      CLKFBOUT_MULT => 5,        -- Multiply value for all CLKOUT, (2-64)
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB, (-360.000-360.000).
      CLKIN1_PERIOD => 5.0,      -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      CLKOUT0_DIVIDE => 8,
      CLKOUT1_DIVIDE => 5,
      CLKOUT2_DIVIDE => 1,
      CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      DIVCLK_DIVIDE => 1,        -- Master division value, (1-56)
      REF_JITTER1 => 0.0,        -- Reference input jitter in UI, (0.000-0.999).
      STARTUP_WAIT => "FALSE"    -- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0 => clock_125,   -- 1-bit output: CLKOUT0
      CLKOUT1 => int_clock,
      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT => feedback_clock, -- 1-bit output: Feedback clock
      LOCKED => open,     -- 1-bit output: LOCK
      CLKIN1 => sysclk,     -- 1-bit input: Input clock
      -- Control Ports: 1-bit (each) input: PLL control ports
      PWRDWN => '0',     -- 1-bit input: Power-down
      RST => int_reset,           -- 1-bit input: Reset
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN => feedback_clock    -- 1-bit input: Feedback clock
   );


    int_reset <= not reset_n;

	ethernetFIFO_inst : entity work.ethernet_with_fifos
    port map(
        clock_125_i        => clock_125,
        reset_i            => int_reset,
        mac_address_i      => x"00AABB00AABB",

        rgmii_rxd     => rgmii_rxd,
        rgmii_rxctl   => rgmii_rxctl,
        rgmii_rxc       => rgmii_rxc,
        rgmii_txd       => rgmii_txd,
        rgmii_txctl     => rgmii_txctl,
        rgmii_txc       => rgmii_txc,
        
        miim_clock_i       => clock_125,
        mdc_o              => mdc_o,
        mdio_io            => mdio_io,
        link_up_o          => link_up_o,
        speed_o            => speed_o,
        speed_override_i   => SPEED_UNSPECIFIED,
        
        -- TX FIFO
        tx_clock_i         => int_clock,
        -- Synchronous reset
        -- When asserted, the content of the buffer was lost.
        -- When full is deasserted the next time, a packet size must be written.
        -- The data of the packet previously being written is not available anymore then.
        tx_reset_o       => open,
        tx_data_i        => (others => '0'),
        tx_wr_en_i       => txbtn,
        tx_full_o        => open,

        -- RX FIFO
        rx_clock_i       => int_clock,
        -- Synchronous reset
        -- When asserted, the content of the buffer was lost.
        -- When empty is deasserted the next time, a packet size must be read out.
        -- The data of the packet previously being read out is not available anymore then.
        rx_reset_o       => open,
        rx_empty_o       => open,
        rx_rd_en_i       => '1',
        rx_data_o        => datarx

    );


end Behavioral;
