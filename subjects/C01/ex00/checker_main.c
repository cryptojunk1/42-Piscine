/* checker_main.c – ft_ft (C01 ex00) */
#include <unistd.h>
void	ft_ft(int *nbr);
static void	putnbr(int n)
{
	char c;
	if (n >= 10) putnbr(n / 10);
	c = '0' + (n % 10);
	write(1, &c, 1);
}
int	main(void)
{
	int	n = 0;
	ft_ft(&n);
	putnbr(n);
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
42
*/
