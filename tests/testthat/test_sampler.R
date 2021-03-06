test_that(paste("sampling functions produce objects of correct",
                "dimensions and give reasonable results"), {
  set.seed(1)

  for (ebnm_fn in c("ebnm_ash", "ebnm_pn")) {

    # No fixed elements.
    l = seq(0.5, 10, by=0.5)
    f = rep(1, 30)
    Y = outer(l, f)
    l = rep(2, 20)
    f = seq(1.1, 4, by=0.1)
    Y = Y + outer(l, f)
    Y = Y + rnorm(20*30)
    data = flash_set_data(Y)
    fit = flash_add_greedy(data, 2, ebnm_fn=ebnm_fn)

    # Check flash_l_sampler.
    lsampler = flash_l_sampler(data, fit)
    lsamp = lsampler(50)
    expect_length(lsamp, 50)
    expect_equal(dim(lsamp[[1]]), c(20, 2))
    var_l = fit$EL2 - fit$EL^2
    sampled_means_l = Reduce(`+`, lsamp) / 50
    expect_equal(sampled_means_l, fit$EL, tolerance = sqrt(var_l))

    # Test LF sampler.
    lfsampler = flash_lf_sampler(data, fit, fixed="f")
    lfsamp = lfsampler(10)
    expect_length(lfsamp, 10)
    expect_equal(dim(lfsamp[[1]]), c(20, 30))

    lf_means = Reduce(`+`, lfsamp) / 10

    # Need to suppress warning about scale parameter being a matrix.
    LF = flash_get_fitted_values(fit)
    suppressWarnings(expect_equal(lf_means, LF, tolerance=0.1, scale=LF))

    # Fix some elements.
    fit = flash_add_fixed_f(data, matrix(1, nrow=30, ncol=1),
            fixf = matrix(c(rep(TRUE,10),rep(FALSE,20)),ncol=1))
    fit = suppressWarnings(flash_backfit(data, fit))

    # Check flash_f_sampler.
    fsampler = flash_f_sampler(data, fit)
    fsamp = fsampler(50)
    expect_length(fsamp, 50)
    expect_length(fsamp[[1]], 30)

    # Make sure the fixed elements stay fixed.
    expect_equal(fsamp[[1]][1:10], rep(1, 10))
    expect_false(fsamp[[1]][11] == 1)
    var_f = fit$EF2 - fit$EF^2
    sampled_means_f = Reduce(`+`, fsamp) / 50
    expect_equal(sampled_means_f[1:10], fit$EF[1:10])
    expect_equal(sampled_means_f[11:30], fit$EF[11:30],
                 tolerance = sqrt(var_f[11:30]))

    flsampler = flash_lf_sampler(data, fit, fixed="l")
    flsamp = flsampler(10)
    expect_length(flsamp, 10)
    expect_equal(dim(flsamp[[1]]), c(20, 30))
  }
})
