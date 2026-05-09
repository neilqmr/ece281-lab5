----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_clk : in STD_LOGIC;
           i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    type state_type is (s_clear, s_A, s_B, s_result);
    signal f_state : state_type := s_clear;

begin

    -- state register
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                f_state <= s_clear;

            elsif i_adv = '1' then
                case f_state is
       
            when s_clear => f_state <= s_A;
            when s_A => f_state <= s_B;
            when s_B => f_state <= s_result;
            when s_result => f_state <= s_clear;
            when others => f_state <= s_clear;
end case;
end if;
end if;
end process;
    process(f_state)
    begin
        case f_state is
            when s_clear => o_cycle <= "0001";
            when s_A => o_cycle <= "0010";
            when s_B => o_cycle <= "0100";
            when s_result => o_cycle <= "1000";
            when others => o_cycle <= "0001";
    end case;
    end process;

end FSM;
