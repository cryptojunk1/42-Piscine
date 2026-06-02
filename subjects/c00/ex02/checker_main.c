/* checker_main.c – ft_print_reverse_alphabet (C00 ex02) */
#include <unistd.h>
void	ft_print_reverse_alphabet(void);
int	main(void)
{
	ft_print_reverse_alphabet();
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_OUTPUT
zyxwvutsrqponmlkjihgfedcba
*/
