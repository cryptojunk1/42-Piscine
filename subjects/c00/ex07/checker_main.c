/* checker_main.c – ft_putnbr (C00 ex07) */
#include <unistd.h>
void	ft_putnbr(int nb);
int	main(void)
{
	ft_putnbr(42);
	write(1, "\n", 1);
	ft_putnbr(-42);
	write(1, "\n", 1);
	ft_putnbr(0);
	write(1, "\n", 1);
	ft_putnbr(2147483647);
	write(1, "\n", 1);
	ft_putnbr(-2147483648);
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
42
-42
0
2147483647
-2147483648
*/
