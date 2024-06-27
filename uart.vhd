entity uart is
  port(
    dado         : in  bit_vector(7 downto 0);
    start        : in  bit;
    TX           : out bit;
    ok           : out bit;
    clock, reset : in  bit
    );
end entity;

architecture structure of uart is
-- sinais internos de controle
begin
-- fd1: entity work.fd port map(
-- entidade do Fluxo de dados
-- );
-- uc1: entity work.uc port map(
-- entidade da Unidade de controle
-- );
end architecture;


entity work.fd is

  port (
    dado : in  it_vector(7 downto 0);
    TX   : out bit);

end entity work.fd;

entity work.uc is
  port(
    start        : in  bit;
    ok           : out bit;
    clock, reset : in  bit
    );

end entity work.uc;
