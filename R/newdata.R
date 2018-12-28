


#' @export
textfeatures.textfeatures_model <- function(text,
                                            sentiment = TRUE,
                                            word_dims = NULL,
                                            normalize = TRUE,
                                            newdata = NULL) {
  if (is.null(newdata)) {
    stop(
      "Failed to supply value to `newdata` (a character vector or data frame ",
      "with a 'text' character vector column)",
      call. = FALSE
    )
  }
  ## rename objects
  tf_model <- text$dict
  text <- newdata

  ## fix newdata format
  if (is.factor(text)) {
    text <- as.character(text)
  }
  if (is.data.frame(text)) {
    text <- text$text
  }
  ## validate newdata
  if (!is.character(text)) {
    stop("`newdata` must be a character vector or data frame with a character ",
      "vector column named 'text'.",
      call. = FALSE)
  }

  ## validate inputs
  stopifnot(
    is.character(text),
    is.logical(sentiment),
    is.atomic(word_dims),
    is.logical(normalize)
  )

  ## initialize output data
  o <- list()

  ## number of URLs/hashtags/mentions
  o$n_urls <- n_urls(text)
  o$n_uq_urls <- n_uq_urls(text)
  o$n_hashtags <- n_hashtags(text)
  o$n_uq_hashtags <- n_uq_hashtags(text)
  o$n_mentions <- n_mentions(text)
  o$n_uq_mentions <- n_uq_mentions(text)

  ## scrub urls, hashtags, mentions
  text <- text_cleaner(text)

  ## count various character types
  o$n_chars <- n_charS(text)
  o$n_uq_chars <- n_uq_charS(text)
  o$n_commas <- n_commas(text)
  o$n_digits <- n_digits(text)
  o$n_exclaims <- n_exclaims(text)
  o$n_extraspaces <- n_extraspaces(text)
  o$n_lowers <- n_lowers(text)
  o$n_lowersp <- (o$n_lowers + 1L) / (o$n_chars + 1L)
  o$n_periods <- n_periods(text)
  o$n_words <- n_words(text)
  o$n_uq_words <- n_uq_words(text)
  o$n_caps <- n_caps(text)
  o$n_nonasciis <- n_nonasciis(text)
  o$n_puncts <- n_puncts(text)
  o$n_capsp <- (o$n_caps + 1L) / (o$n_chars + 1L)
  o$n_charsperword <- (o$n_chars + 1L) / (o$n_words + 1L)

  ## estimate sentiment
  if (sentiment) {
    o$sent_afinn <- sentiment_afinn(text)
    o$sent_bing <- sentiment_bing(text)
    o$sent_syuzhet <- sentiment_syuzhet(text)
    o$sent_vader <- sentiment_vader(text)
  }

  ## length
  n_obs <- length(text)

  ## tokenize into words
  text <- prep_wordtokens(text)

  ## if applicable, get w2v estimates
  sh <- TRUE
  sh <- tryCatch(
    capture.output(w <- word_dims_newtext(tf_model, text)),
    error = function(e) return(FALSE))
  if (identical(sh, FALSE)) {
    w <- NULL
  }

  ## count number of polite, POV, to-be, and preposition words.
  o$n_polite <- politeness(text)
  o$n_first_person <- first_person(text)
  o$n_first_personp <- first_personp(text)
  o$n_second_person <- second_person(text)
  o$n_second_personp <- second_personp(text)
  o$n_third_person <- third_person(text)
  o$n_tobe <- to_be(text)
  o$n_prepositions <- prepositions(text)

  ## convert to tibble
  o <- tibble::as_tibble(o)

  ## merge with w2v estimates
  o <- dplyr::bind_cols(o, w)

  ## make exportable
  m <- vapply(o, mean, na.rm = TRUE, FUN.VALUE = numeric(1))
  s <- vapply(o, stats::sd, na.rm = TRUE, FUN.VALUE = numeric(1))
  e <- list(avg = m, std_dev = s)
  e$dict <- attr(w, "dict")

  ## normalize
  if (normalize) {
    o <- scale_normal(scale_count(o))
  }

  ## store export list as attribute
  attr(o, "tf_export") <- e

  ## return
  o
}


tf_export <- function(x) attr(x, "tf_export")