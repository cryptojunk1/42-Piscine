/* checker_main.c – ft_print_comb2 (C00 ex06) */
#include <unistd.h>
void	ft_print_comb2(void);
int	main(void)
{
	ft_print_comb2();
	write(1, "\n", 1);
	return (0);
}
/* EXPECTED_PARTIAL_START
00 01, 00 02, 00 03
*/
/* EXPECTED_PARTIAL_END
98 99
*/
/* CHECK_MODE: partial */
