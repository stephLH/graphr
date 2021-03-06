#' quali_uni
#'
#' @param champ_quali \dots
#' @param lib_pct \dots
#' @param max_modalites \dots
#' @param lib_modalite_autre \dots
#' @param choix_multiple \dots
#' @param marge_gauche \dots
#' @param taille_texte \dots
#'
#' @export
quali_uni <- function(champ_quali, lib_pct = TRUE, max_modalites = NULL, lib_modalite_autre = NULL, choix_multiple = FALSE, marge_gauche = FALSE, taille_texte = 3.5) {

  if (length(stats::na.omit(champ_quali)) == 0) {

    cat("Effectif nul")
    return(invisible(NULL))

  }

  stats <- stats_count_uni(champ_quali, max_modalites, lib_modalite_autre, choix_multiple)

  if (nrow(stats) == 0) {

    if (is.factor(stats$champ_quali)) {

      stats <- stats %>%
        dplyr::add_row(
          champ_quali = utils::tail(levels(stats$champ_quali), 1),
          n = 0
        )

    } else {

      cat("Effectif nul")
      return(invisible(NULL))

    }

  }

  if (!is.factor(stats$champ_quali)) {

    if (is.null(stats[["ordre"]])) {
      stats <- dplyr::mutate(stats, ordre = -dplyr::row_number())
    }

    plot <- stats %>%
      ggplot2::ggplot(
        ggplot2::aes(
          x = stats::reorder(champ_quali, .data$ordre),
          y = .data$n, fill = champ_quali
        )
      )

  } else {

    plot <- stats %>%
      ggplot2::ggplot(
        ggplot2::aes(
          x = factor(champ_quali, levels = rev(levels(champ_quali))),
          y = .data$n,
          fill = champ_quali
        )
      )

  }

  plot <- plot +
    ggplot2::geom_col(show.legend = FALSE, width = 0.5) +
    ggplot2::scale_x_discrete(drop = FALSE) +
    ggplot2::scale_y_continuous(breaks = echelle_integer(stats$n)) +
    ggplot2::coord_flip() +
    ggplot2::theme_bw()

  if (lib_pct == FALSE | choix_multiple == TRUE) {

    plot <- plot + ggplot2::geom_text(
      stat = "identity",
      size = taille_texte,
      ggplot2::aes(
        y = 0.2,
        hjust = 0,
        label = dplyr::if_else(
          .data$n >= 1,
          scales::number(.data$n, accuracy = 1, big.mark = "\u202F")
          , ""
        )
      )
    )

  } else {
    plot <- plot +
      ggplot2::geom_text(
        stat = "identity",
        size = taille_texte,
        ggplot2::aes(
          y = 0.2,
          hjust = 0,
          label = paste0(
            scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
            " (", .data$pct, ")"
          )
        )
      )

  }

  plot <- plot +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = taille_texte * 3))

  if (marge_gauche == TRUE) {
    plot <- plot + ggplot2::labs(x = "", y = NULL)
  } else {
    plot <- plot + ggplot2::labs(x = NULL, y = NULL)
  }

  texte_repondants <- pct_repondants(sum(stats$n), length(champ_quali))

  if (!is.null(texte_repondants)) {

    plot <- plot +
      ggplot2::labs(title = texte_repondants) +
      ggplot2::theme(plot.title = ggplot2::element_text(size = 8, hjust = 1, margin = ggplot2::margin(b = 5)))

  }

  return(plot)

}

#' quali_uni_aires
#'
#' @param champ_x \dots
#' @param identifiant \dots
#' @param n_graph \dots
#' @param n_population \dots
#' @param label_pourcentage \dots
#' @param label_pourcentage_saut_ligne \dots
#'
#' @export
quali_uni_aires <- function(champ_x, identifiant, n_graph, n_population, label_pourcentage = FALSE, label_pourcentage_saut_ligne = TRUE) {

  if (length(stats::na.omit(champ_x)) == 0) {

    cat("effectif nul")
    return("")

  }

  stats <- stats_count_uni(champ_x) %>%
    dplyr::group_by(.data$champ_quali) %>%
    dplyr::mutate(pos = .data$n) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(pct = scales::percent(.data$n / n_population, decimal.mark = ",", suffix = "\u202F%")) %>%
    dplyr::full_join(
      dplyr::tibble(
        champ_quali = factor(levels(champ_x)),
        champ_x = 1:length(levels(champ_x))
      ),
      by = "champ_quali"
    ) %>%
    dplyr::arrange(champ_x) %>%
    dplyr::mutate(n = dplyr::if_else(is.na(.data$n), 0, .data$n))

  if (nrow(stats) == 0) {

    if (is.factor(stats$champ_x)) {

      stats <- stats %>%
        dplyr::add_row(
          champ_x = utils::tail(levels(stats$champ_x), 1),
          n = 0
        )

    } else {

      cat("effectif nul")
      return("")

    }

  }

  echelle_y <- dplyr::group_by(stats, champ_x) %>%
    dplyr::summarise(n = sum(.data$n)) %>%
    dplyr::pull(.data$n) %>%
    echelle_integer()

  plot <- stats %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = champ_x,
        y = .data$n,
        fill = ""
      )
    ) +
    ggplot2::geom_area(show.legend = FALSE) +
    ggplot2::scale_x_continuous(
      breaks = 1:length(levels(champ_x)),
      labels = levels(champ_x)
    ) +
    ggplot2::scale_y_continuous(breaks = echelle_y) +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_bw()

  if (label_pourcentage == TRUE) {

    if (label_pourcentage_saut_ligne == TRUE) {

      plot <- plot +
        ggplot2::geom_text(
          data = dplyr::filter(stats, .data$n != 0),
          stat = "identity",
          ggplot2::aes(
            label = paste0(
              scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
              "\n(", .data$pct,")"
            ),
            y = .data$pos
          ),
          size = 3
        )

    } else {

      plot <- plot +
        ggplot2::geom_text(
          data = dplyr::filter(stats, .data$n != 0),
          stat = "identity",
          ggplot2::aes(
            label = paste0(
              scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
              " (", .data$pct,")"
            ),
            y = .data$pos
          ),
          size = 3
        )

    }

  }

  texte_repondants <- pct_repondants(identifiant %>% unique() %>% length(), n_graph)

  if (!is.null(texte_repondants)) {

    plot <- plot +
      ggplot2::labs(title = texte_repondants) +
      ggplot2::theme(plot.title = ggplot2::element_text(size = 8, hjust = 1, margin = ggplot2::margin(b = 5)))

  }

  return(plot)
}

#' quali_uni_secteurs
#'
#' @param champ_quali \dots
#' @param max_modalites \dots
#' @param marge_gauche \dots
#' @param effectif \dots
#' @param taille_texte \dots
#' @param marges \dots
#'
#' @export
quali_uni_secteurs <- function(champ_quali, max_modalites = NULL, marge_gauche = FALSE, effectif = TRUE, taille_texte = 3.5, marges = TRUE) {

  if (length(stats::na.omit(champ_quali)) == 0) {

    cat("effectif nul")
    return("")

  }

  stats <- stats_count_uni(champ_quali, max_modalites = max_modalites)

  if (nrow(stats) == 0) {
    if (is.factor(stats$champ_quali)) {
      stats <- stats %>%
        dplyr::add_row(
          champ_quali = utils::tail(levels(stats$champ_quali), 1),
          n = 0
        )
    } else {
      cat("effectif nul")
      return("")
    }
  }

  if (!is.factor(stats$champ_quali)) {

    if (is.null(stats[["ordre"]])) {
      stats <- dplyr::mutate(stats, ordre = -dplyr::row_number())
    }

    plot <- ggplot2::ggplot(stats, ggplot2::aes(x = stats::reorder(.data$champ_quali, .data$ordre), y = .data$n, fill = .data$champ_quali))
  } else {
    plot <- ggplot2::ggplot(stats, ggplot2::aes(x = factor(champ_quali, levels = rev(levels(champ_quali))), y = .data$n, fill = champ_quali))
  }

  plot <- ggplot2::ggplot(stats, ggplot2::aes(x = "", y = rev(.data$n), fill = champ_quali)) +
    ggplot2::geom_bar(show.legend = FALSE, width = 1, stat = "identity")

  if (effectif == TRUE) {

    plot <- plot +
      ggplot2::geom_text(
        size = taille_texte,
        ggplot2::aes(
          y = .data$n/2 + c(0, cumsum(.data$n)[-length(.data$n)]),
          label = paste0(
            champ_quali,
            "\n",
            scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
            " (", .data$pct, ")"
          )
        )
      )

  } else {

    plot <- plot +
      ggplot2::geom_text(
        size = taille_texte,
        ggplot2::aes(
          y = .data$n/2 + c(0, cumsum(.data$n)[-length(.data$n)]),
          label = glue::glue("{champ_quali}\n{pct}")
        )
      )

  }

  plot <- plot +
    ggplot2::coord_polar("y", start = 0) +
    ggplot2::theme(
      axis.ticks = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank()
    )

  if (marges == FALSE) {

    plot <- plot +
      ggplot2::theme(plot.margin = ggplot2::margin(t = -1, r = -1, b = -1, l = -1, unit = "cm"))

  }

  if (marge_gauche == TRUE) {

    plot <- plot + ggplot2::labs(x = "", y = NULL)

  } else {

    plot <- plot + ggplot2::labs(x = NULL, y = NULL)

  }

  texte_repondants <- pct_repondants(sum(stats$n), length(champ_quali))

  if (!is.null(texte_repondants)) {

    plot <- plot +
      ggplot2::labs(title = texte_repondants) +
      ggplot2::theme(plot.title = ggplot2::element_text(size = 8, hjust = 1, margin = ggplot2::margin(b = 5)))

  }

  return(plot)

}

#' quali_bi_aires
#'
#' @param champ_quali \dots
#' @param champ_x \dots
#' @param identifiant \dots
#' @param label_pourcentage \dots
#' @param position_legende \dots
#' @param taille_texte_legende \dots
#' @param nombre_lignes_legende \dots
#' @param palette_ordinal \dots
#'
#' @export
quali_bi_aires <- function(champ_quali, champ_x, identifiant, label_pourcentage = FALSE, position_legende = "bas", taille_texte_legende = 1, nombre_lignes_legende = NULL, palette_ordinal = FALSE) {

  if (length(stats::na.omit(champ_quali)) == 0) {

    cat("effectif nul")
    return("")

  }

  stats <- stats_count_bi(champ_quali, champ_x, identifiant, complet = TRUE)

  if (position_legende == "droite") {

    stats <- dplyr::mutate(stats, pos = length(unique(identifiant)) - .data$pos)

  }

  if (nrow(stats) == 0) {

    if (is.factor(stats$champ_x)) {

      stats <- stats %>%
        dplyr::add_row(
          champ_x = utils::tail(levels(stats$champ_x), 1),
          n = 0
        )

    } else {

      cat("effectif nul")
      return("")

    }

  }

  if (position_legende == "bas") {

    plot <- stats %>%
      ggplot2::ggplot(
        ggplot2::aes(
          x = as.numeric(champ_x),
          y = .data$n,
          fill = factor(champ_quali, levels = rev(levels(champ_quali))),
          order = rev(champ_quali)
        )
      )

  } else if (position_legende == "droite") {

    plot <- stats %>%
      ggplot2::ggplot(
        ggplot2::aes(
          x = as.numeric(champ_x),
          y = .data$n, fill = champ_quali
        )
      )

  }

  echelle_y <- stats %>%
    dplyr::group_by(champ_x) %>%
    dplyr::summarise(n = sum(.data$n)) %>%
    dplyr::pull(.data$n) %>%
    echelle_integer()

  plot <- plot +
    ggplot2::geom_area() +
    ggplot2::scale_x_continuous(
      breaks = stats$champ_x %>%
        as.numeric() %>%
        unique(),
      labels = levels(champ_x)
    ) +
    ggplot2::scale_y_continuous(breaks = echelle_y) +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.title = ggplot2::element_blank(),
      legend.key.size = ggplot2::unit(taille_texte_legende, 'lines'),
      legend.text = ggplot2::element_text(size = 8),
      legend.position = dplyr::recode(position_legende, "bas" = "bottom", "droite" = "right"),
      legend.box.spacing = ggplot2::unit(1, "mm")
    )

  if (palette_ordinal == TRUE) {

    plot <- plot + ggplot2::scale_fill_brewer()

  } else {

    plot <- plot + ggplot2::scale_fill_discrete(direction = -1)

  }

  if (label_pourcentage == TRUE) {

    plot <- plot +
      ggplot2::geom_text(
        data = dplyr::filter(stats, .data$n != 0),
        stat = "identity",
        ggplot2::aes(
          label = paste0(
            scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
            " (", .data$pct,")"
          ),
          y = .data$pos),
        size = 3
      )

  } else {

    plot <- plot +
      ggplot2::geom_text(
        data = dplyr::filter(stats, .data$n != 0),
        stat = "identity",
        ggplot2::aes(
          label = scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
          y = .data$pos
        ),
        size = 3
      )

  }

  if (position_legende == "bas") {

    plot <- plot +
      ggplot2::guides(fill = ggplot2::guide_legend(reverse = TRUE, byrow = TRUE))

    if (!is.null(nombre_lignes_legende)) {

      plot <- plot +
        ggplot2::guides(fill = ggplot2::guide_legend(nrow = nombre_lignes_legende, byrow = TRUE, reverse = TRUE))

    }
  }

  texte_repondants <- pct_repondants(sum(stats$n), length(champ_quali))

  if (!is.null(texte_repondants)) {

    plot <- plot +
      ggplot2::labs(title = texte_repondants) +
      ggplot2::theme(plot.title = ggplot2::element_text(size = 8, hjust = 1, margin = ggplot2::margin(b = 5)))

  }

  return(plot)
}

#' quali_bi_ordinal
#'
#' @param champ_quali \dots
#' @param champ_valeur \dots
#' @param identifiant \dots
#' @param taille_texte \dots
#' @param taille_texte_legende \dots
#' @param orientation \dots
#' @param label_pourcentage \dots
#'
#' @export
quali_bi_ordinal <- function(champ_quali, champ_valeur, identifiant, taille_texte = 3, taille_texte_legende = 1, orientation = "horizontal", label_pourcentage = FALSE) {

  if (length(stats::na.omit(champ_quali)) == 0) {

    cat("effectif nul")
    return("")

  }

  stats <- stats_count_bi(champ_quali, champ_valeur) %>%
    dplyr::rename(champ_valeur = .data$champ_x) %>%
    dplyr::arrange(champ_quali, champ_valeur) %>%
    tidyr::drop_na(champ_valeur) %>%
    dplyr::left_join(
      dplyr::group_by(., champ_quali) %>%
        dplyr::summarise(total = sum(.data$n)),
      by = "champ_quali"
    ) %>%
    dplyr::group_by(champ_quali) %>%
    dplyr::mutate(
      pct = .data$n / .data$total,
      pos1 = cumsum(.data$n),
      pos2 = c(0, utils::head(.data$pos1, -1)),
      pos3 = .data$pos2 + .data$n / 2,
      pos4 = c(utils::head(.data$pos3, 1), diff(.data$pos3)),
      pos = .data$pos4 / .data$total
    ) %>%
    dplyr::ungroup()

  if (nrow(stats) == 0) {

    if (is.factor(stats$champ_quali)) {

      stats <- stats %>%
        dplyr::ungroup() %>%
        dplyr::add_row(
          champ_quali = utils::tail(levels(stats$champ_quali), 1),
          n = 0, total = 0, pct = 0
        )

    } else {

      cat("effectif nul")
      return("")

    }

  }

  plot <- stats %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = champ_quali,
        y = .data$pct,
        fill = factor(champ_valeur, levels = rev(levels(champ_valeur)))
      )
    ) +
    ggplot2::geom_col(width = 0.5) +
    ggplot2::scale_fill_brewer() +
    ggplot2::scale_y_continuous(limits = c(0, 1), labels = scales::percent)

  if (label_pourcentage == TRUE) {

    plot <- plot +
      ggplot2::geom_text(
        data = dplyr::filter(stats, .data$n != 0),
        position = "stack",
        size = 3,
        ggplot2::aes(
          y = .data$pos,
          label = paste0(
            scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
            " (",
            scales::percent(.data$pct, decimal.mark = ",", suffix = "\u202F%"),
            ")"
          )
        )
      )

  } else {

    plot <- plot +
      ggplot2::geom_text(
        position = "stack",
        size = 3,
        ggplot2::aes(
          y = .data$pos,
          label = scales::number(.data$n, accuracy = 1, big.mark = "\u202F")
        )
      )

  }

  if (orientation == "horizontal") {

    plot <- plot +
      ggplot2::scale_x_discrete(drop = FALSE, limits = rev(levels(champ_quali))) +
      ggplot2::coord_flip()


  } else if (orientation == "vertical") {

    plot <- plot +
      ggplot2::scale_x_discrete(drop = FALSE, limits = levels(champ_quali))

  }

  plot <- plot +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.title = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.box.spacing = ggplot2::unit(1, "mm"),
      legend.text = ggplot2::element_text(size = 8),
      legend.key.size = ggplot2::unit(taille_texte_legende, 'lines')
    ) +
    ggplot2::guides(fill = ggplot2::guide_legend(reverse = TRUE))

  texte_repondants <- dplyr::tibble(
    champ_quali = champ_quali,
    champ_valeur = champ_valeur,
    identifiant = identifiant
  ) %>%
    tidyr::drop_na(champ_valeur) %>%
    dplyr::group_by(identifiant) %>%
    dplyr::summarise_at("champ_valeur", paste, collapse = "") %>%
    dplyr::ungroup() %>%
    nrow() %>%
    pct_repondants(max(stats$total), .)

  if (!is.null(texte_repondants)) {

    plot <- plot +
      ggplot2::labs(title = texte_repondants) +
      ggplot2::theme(plot.title = ggplot2::element_text(size = 8, hjust = 1, margin = ggplot2::margin(b = 5)))

  }

  return(plot)
}

#' quali_bi
#'
#' @param champ_quali \dots
#' @param champ_valeur \dots
#' @param identifiant \dots
#' @param taille_texte \dots
#' @param taille_texte_legende \dots
#' @param orientation \dots
#' @param label_pourcentage \dots
#'
#' @export
quali_bi <- function(champ_quali, champ_valeur, identifiant, taille_texte = 3, taille_texte_legende = 1, orientation = "horizontal", label_pourcentage = FALSE) {

  if (length(stats::na.omit(champ_quali)) == 0) {

    cat("effectif nul")
    return("")

  }

  if (length(stats::na.omit(champ_valeur)) == 0) {

    cat("Aucune donn\u00E9e non-nulle")
    return("")

  }

  stats <- stats_count_bi(champ_valeur, champ_quali, identifiant)

  if (nrow(stats) == 0) {

    if (is.factor(stats$champ_x)) {

      stats <- stats %>%
        dplyr::add_row(
          champ_x = utils::tail(levels(stats$champ_x), 1),
          n = 0
        )

    } else {

      cat("effectif nul")
      return("")

    }

  }

  echelle_y <- dplyr::group_by(stats, .data$champ_x) %>%
    dplyr::summarise(n = sum(.data$n)) %>%
    dplyr::pull(.data$n) %>%
    echelle_integer()

  plot <- stats %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$champ_x,
        y = .data$n,
        fill = factor(champ_quali, levels = rev(levels(champ_quali)))
      )
    ) +
    ggplot2::geom_col(width = 0.5) +
    ggplot2::scale_fill_discrete(direction = -1) +
    ggplot2::scale_y_continuous(breaks = echelle_y)

  if (label_pourcentage == TRUE) {

    plot <- plot +
      ggplot2::geom_text(
        data = dplyr::filter(stats, .data$n != 0),
        position = "identity",
        size = 3,
        ggplot2::aes(
          y = .data$pos,
          label = paste0(
            scales::number(.data$n, accuracy = 1, big.mark = "\u202F"),
            " (",
            scales::percent(.data$pct, decimal.mark = ",", suffix = "\u202F%"),
            ")"
          )
        )
      )

  } else {

    plot <- plot +
      ggplot2::geom_text(
        position = "identity",
        size = 3,
        ggplot2::aes(
          y = .data$pos,
          label = scales::number(.data$n, accuracy = 1, big.mark = "\u202F")
        )
      )

  }

  if (orientation == "horizontal") {

    plot <- plot +
      ggplot2::scale_x_discrete(drop = FALSE, limits = rev(levels(.data$champ_x))) +
      ggplot2::coord_flip()


  } else if (orientation == "vertical") {

    plot <- plot + ggplot2::scale_x_discrete(drop = FALSE, limits = levels(champ_quali))

  }

  plot <- plot +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.title = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.box.spacing = ggplot2::unit(1, "mm"),
      legend.text = ggplot2::element_text(size = 8),
      legend.key.size = ggplot2::unit(taille_texte_legende, 'lines')
    ) +
    ggplot2::guides(fill = ggplot2::guide_legend(reverse = TRUE))

  return(plot)
}

#' quali_bi_aires2
#'
#' @param champ_quali \dots
#' @param champ_x \dots
#' @param label_effectif \dots
#' @param position_legende \dots
#' @param taille_texte_legende \dots
#' @param taille_texte_axe_x \dots
#' @param nombre_lignes_legende \dots
#' @param palette_ordinal \dots
#'
#' @export
quali_bi_aires2 <- function(champ_quali, champ_x, label_effectif = FALSE, position_legende = "bas", taille_texte_legende = 1, taille_texte_axe_x = 9, nombre_lignes_legende = NULL, palette_ordinal = FALSE) {

  if (length(stats::na.omit(champ_quali)) == 0) {

    cat("effectif nul")
    return("")

  }

  stats <- dplyr::tibble(champ_x = champ_x, champ_quali = champ_quali)

  stats <- stats %>%
    dplyr::count(champ_x, champ_quali) %>%
    dplyr::left_join(
      dplyr::count(stats, champ_x) %>%
        dplyr::rename(n_total = .data$n),
      by = "champ_x"
    ) %>%
    dplyr::mutate(
      pct = .data$n / .data$n_total,
      lib_pct = scales::percent(.data$pct, decimal.mark = ",", suffix = "\u202F%")
    ) %>%
    dplyr::group_by(champ_x) %>%
    dplyr::mutate(pos = cumsum(.data$pct) - 0.5 * .data$pct) %>%
    dplyr::ungroup()

  if (position_legende == "droite") {
    stats <- dplyr::mutate(stats, pos = 1 - .data$pos)
  }

  if (nrow(stats) == 0) {

    if (is.factor(stats$champ_x)) {

      stats <- stats %>%
        dplyr::add_row(
          champ_x = utils::tail(levels(stats$champ_x), 1),
          n = 0
        )

    } else {

      cat("effectif nul")
      return("")

    }

  }

  if (position_legende == "bas") {

    plot <- stats %>%
      ggplot2::ggplot(
        ggplot2::aes(
          x = as.numeric(champ_x),
          y = .data$pct,
          fill = factor(champ_quali, levels = rev(levels(champ_quali))), order = rev(champ_quali)
        )
      )

  } else if (position_legende == "droite") {

    plot <- stats %>%
      ggplot2::ggplot(
        ggplot2::aes(
          x = as.numeric(champ_x),
          y = .data$pct,
          fill = champ_quali
        )
      )

  }

  plot <- plot +
    ggplot2::geom_area() +
    ggplot2::scale_x_continuous(
      breaks = stats$champ_x %>%
        as.numeric() %>%
        unique(),
      labels = levels(champ_x)
    ) +
    ggplot2::scale_y_continuous(
      breaks = seq(0, 1, by = 0.2),
      labels = seq(0, 1, by = 0.2) %>%
        scales::percent(decimal.mark = ",", suffix = "\u202F%")
    ) +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.title = ggplot2::element_blank(),
      legend.key.size = ggplot2::unit(taille_texte_legende, 'lines'),
      legend.text = ggplot2::element_text(size = 8),
      legend.position = dplyr::recode(position_legende, "bas" = "bottom", "droite" = "right"),
      legend.box.spacing = ggplot2::unit(1, "mm"),
      axis.text.x = ggplot2::element_text(size = taille_texte_axe_x)
    )

  if (palette_ordinal == TRUE) {

    plot <- plot + ggplot2::scale_fill_brewer()

  } else {

    plot <- plot + ggplot2::scale_fill_discrete(direction = -1)

  }

  if (label_effectif == TRUE) {

    plot <- plot +
      ggplot2::geom_text(
        data = dplyr::filter(stats, .data$n != 0),
        stat = "identity",
        ggplot2::aes(
          label = glue::glue("{lib_pct}\n({n})"),
          y = .data$pos
        ),
        size = 3
    )

  } else {

    plot <- plot +
      ggplot2::geom_text(
        data = dplyr::filter(stats, .data$n != 0),
        stat = "identity",
        ggplot2::aes(
          label = .data$lib_pct,
          y = .data$pos
        ),
        size = 3
      )

  }

  if (position_legende == "bas") {

    plot <- plot + ggplot2::guides(fill = ggplot2::guide_legend(reverse = TRUE, byrow = TRUE))

    if (!is.null(nombre_lignes_legende)) {

      plot <- plot + ggplot2::guides(fill = ggplot2::guide_legend(nrow = nombre_lignes_legende, byrow = TRUE, reverse = TRUE))

    }
  }

  texte_repondants <- pct_repondants(sum(stats$n), length(champ_quali))

  if (!is.null(texte_repondants)) {

    plot <- plot +
      ggplot2::labs(title = texte_repondants) +
      ggplot2::theme(plot.title = ggplot2::element_text(size = 8, hjust = 1, margin = ggplot2::margin(b = 5)))

  }

  return(plot)
}
