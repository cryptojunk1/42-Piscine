/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   ft_print_alphabet.c                                  :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rene <rene@42.fr>                          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/06/01 13:59:58 by rene              #+#    #+#             */
/*   Updated: 2026/06/01 13:59:58 by rene             ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include <unistd.h>

/* Create a function that displays the alphabet in lowercase on a single line, ascending order, starting from 'a'. */
/* Erlaubt: write */

void ft_print_alphabet(void)
{
    char c;
    c = 'a';
    while (c <= 'z')
    {
        write(1, &c, 1);
        c++;
    }
}
