/* checker_main.c – ft_swap (C01 ex02) */
#include <unistd.h>
void	ft_swap(int *a, int *b);
static void	putnbr(int n)
{
	char c;
	if (n < 0) { write(1, "-", 1); n = -n; }
	if (n >= 10) putnbr(n / 10);
	c = '0' + (n % 10);
	write(1, &c, 1);
}
int	main(void)
{
	int	a = 3;
	int	b = 7;
	ft_swap(&a, &b);
	putnbr(a); write(1, "\n", 1);
	putnbr(b); write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
7
3
*/
