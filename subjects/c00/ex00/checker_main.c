/* checker_main.c – ft_putchar (C00 ex00) */
#include <unistd.h>
void	ft_putchar(char c);
int	main(void)
{
	ft_putchar('H');
	ft_putchar('e');
	ft_putchar('l');
	ft_putchar('l');
	ft_putchar('o');
	write(1, "\n", 1);
	ft_putchar('4');
	ft_putchar('2');
	write(1, "\n", 1);
	ft_putchar('Z');
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
Hello
42
Z
*/
