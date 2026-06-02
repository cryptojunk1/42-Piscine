/* checker_main.c – ft_ultimate_div_mod (C01 ex04) */
#include <unistd.h>
void	ft_ultimate_div_mod(int *a, int *b);
static void	putnbr(int n)
{
	char c;
	if (n >= 10) putnbr(n / 10);
	c = '0' + (n % 10);
	write(1, &c, 1);
}
int	main(void)
{
	int	a = 10, b = 3;
	ft_ultimate_div_mod(&a, &b);
	putnbr(a); write(1, "\n", 1);
	putnbr(b); write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
3
1
*/
