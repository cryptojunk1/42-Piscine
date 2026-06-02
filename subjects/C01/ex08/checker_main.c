/* checker_main.c – ft_sort_int_tab (C01 ex08) */
#include <unistd.h>
void	ft_sort_int_tab(int *tab, int size);
static void	putnbr(int n)
{
	char c;
	if (n >= 10) putnbr(n / 10);
	c = '0' + (n % 10);
	write(1, &c, 1);
}
int	main(void)
{
	int	tab[] = {5, 2, 8, 1, 3};
	int	i = 0;
	ft_sort_int_tab(tab, 5);
	while (i < 5)
	{
		putnbr(tab[i]); write(1, "\n", 1);
		i++;
	}
	return (0);
}
/* EXPECTED_OUTPUT
1
2
3
5
8
*/
