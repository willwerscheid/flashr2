# Functions for extracting useful information about the object.

#' @title Estimate LF'
#'
#' @description Return the estimated LF' matrix.
#'
#' @inheritParams flash_get_ldf
#'
#' @return The estimated value of LF', an n by p matrix.
#'
#' @export
#'
flash_get_fitted_values = function(f) {
  if (is.null(f$EL)) {
    return(NULL)
  }
  return(f$EL %*% t(f$EF))
}

#' @title Get LDF from a flash object
#'
#' @description Returns standardized loadings, factors, and weights from
#' a flash object.
#'
#' @param f A flash fit object.
#'
#' @param kset Indices of loadings/factors to be returned.
#'
#' @param drop_zero_factors If \code{TRUE}, then any factor/loadings
#'   that are zero will be removed.
#'
#' @return A list with the following elements. These are analogous to
#'   the \code{u}, \code{d} and \code{v} returned by \code{svd}, but
#'   the columns of \code{l} and \code{f} are not orthogonal.
#'
#'   \item{\code{l}}{A matrix whose columns contain the standardized
#'     loadings (i.e., with norm 1).}
#'
#'   \item{\code{d}}{A vector of weights (analogous to the singular
#'     values in an SVD).}
#'
#'   \item{\code{f}}{A matrix whose columns contain the standardized
#'     factors (i.e., with norm 1).}
#'
#' @export
#'
flash_get_ldf = function(f, kset = NULL, drop_zero_factors = TRUE) {
  kset = handle_kset(kset, f)
  ll = f$EL[, kset, drop=FALSE]
  ff = f$EF[, kset, drop=FALSE]
  d = sqrt(colSums(ll^2) * colSums(ff^2))

  ll = scale(ll, scale=sqrt(colSums(ll^2)), center=FALSE)
  ff = scale(ff, scale=sqrt(colSums(ff^2)), center=FALSE)

  if(drop_zero_factors) {
    ll = ll[, d!=0, drop=FALSE]
    ff = ff[, d!=0, drop=FALSE]
    d = d[d!=0, drop=FALSE]
  }

  list(d = d,
       l = ll,
       f = ff)
}

#' @title Get number of factors in a flash object
#'
#' @description Returns the number of factors in a flash object.
#'   Factors that have been zeroed out are not counted.
#'
#' @inheritParams flash_get_ldf
#'
#' @export
#'
flash_get_nfactors = function(f) {
  ldf = flash_get_ldf(f)
  return(length(ldf$d))
}

#' @title Get PVE from a flash object
#'
#' @description Returns the factor contributions (proportion of
#' variance explained) for each factor/loading combination in flash
#' fit \code{f}. Because the factors are not required to be orthogonal,
#' this should be interpreted loosely: e.g., PVE could total more than 1.
#'
#' @inheritParams flash_get_ldf
#'
#' @export
#'
flash_get_pve = function(f, drop_zero_factors = TRUE) {
  s = (flash_get_ldf(f, drop_zero_factors=drop_zero_factors)$d)^2
  tau = f$tau[f$tau != 0]
  s/(sum(s) + sum(1/tau))
}

# @title Get the residuals from a flash data and fit object,
#   excluding factor k.
flash_get_Rk = function(data, f, k) {
    if (flash_get_k(f) < k) {
        stop("factor k does not exist")
    }
    return(data$Y - f$EL[, -k, drop = FALSE] %*% t(f$EF[, -k, drop = FALSE]))
}

# @title Get the residuals from data and a flash fit object.
flash_get_R = function(data, f) {

    # If f is null, return Y.
    if (is.null(f$EL))
        {
            return(data$Y)
        }
 else {
        return(data$Y - flash_get_fitted_values(f))
    }
}

# @title Get the residuals from data and a flash fit object, with
#   missing data as in original.
flash_get_R_withmissing = function(data, f) {

    # If f is null, return Y.
    if (is.null(f$EL))
        {
            return(get_Yorig(data))
        }
 else {
        return(get_Yorig(data) - flash_get_fitted_values(f))
    }
}

# @title Get the expected squared residuals from a flash data and fit
# object.
flash_get_R2 = function(data, f) {
    if (is.null(f$EL)) {
        return(data$Y^2)
    } else {
        LF = f$EL %*% t(f$EF)
        return((data$Y - LF)^2 + f$EL2 %*% t(f$EF2) - f$EL^2 %*% t(f$EF^2))
    }
}

# @title Get the expected squared residuals from a flash data and fit
#   object excluding factor k.
flash_get_R2k = function(data, f, k) {
    if (is.null(f$EL)) {
        return(data$Y^2)
    } else {
        return(flash_get_Rk(data, f, k)^2 +
               f$EL2[, -k, drop = FALSE] %*% t(f$EF2[, -k, drop = FALSE]) -
               f$EL[, -k, drop = FALSE]^2 %*%
               t(f$EF[, -k, drop = FALSE]^2))
    }
}

# @title is_tiny_fl
# @details Checks whether kth factor/loading combination is tiny.
is_tiny_fl = function(f, k, tol = 1e-08) {
    return(sum(f$EL[, k]^2) * sum(f$EF[, k]^2) < tol)
}

flash_get_l = function(f) {
  f$EL
}

flash_get_f = function(f) {
  f$EF
}

# @title Get number of factors in a fit object.
# @details Returns the number of factors in a flash fit.
flash_get_k = function(f) {
    k = ncol(f$EL)
    if (is.null(k)) {
        return(0)
    } else {
        return(k)
    }
}

flash_get_n = function(f) {
    nrow(f$EL)
}

flash_get_p = function(f) {
  nrow(f$EF)
}
