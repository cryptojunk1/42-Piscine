/* checker_main.c – ft_div_mod (C01 ex03) */
#include <unistd.h>
void	ft_div_mod(int a, int b, int *div, int *mod);
static void	putnbr(int n)
{
	char c;
	if (n >= 10) putnbr(n / 10);
	c = '0' + (n % 10);
	write(1, &c, 1);
}
int	main(void)
{
	int	d, m;
	ft_div_mod(10, 3, &d, &m);
	putnbr(d); write(1, "\n", 1);
	putnbr(m); write(1, "\n", 1);
	ft_div_mod(7, 2, &d, &m);
	putnbr(d); write(1, "\n", 1);
	putnbr(m); write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
3
1
3
1
*/
