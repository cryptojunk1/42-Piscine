/* checker_main.c – ft_print_alphabet (C00 ex01) */
#include <unistd.h>
void	ft_print_alphabet(void);
int	main(void)
{
	ft_print_alphabet();
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
abcdefghijklmnopqrstuvwxyz
*/
