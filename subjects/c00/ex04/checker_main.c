/* checker_main.c – ft_is_negative (C00 ex04) */
#include <unistd.h>
void	ft_is_negative(int n);
int	main(void)
{
	ft_is_negative(-1);
	ft_is_negative(0);
	ft_is_negative(42);
	ft_is_negative(-2147483648);
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
NPPN
*/
