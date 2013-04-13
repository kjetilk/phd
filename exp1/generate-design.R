sparqltest.design <- cross.design(
                                  fac.design(nlevels = 2, nfactors = 3,
                                             factor.names = c("Implement", "TripleC", "Machine"), randomize = F),
                                  fac.design(nlevels = 2, nfactors = 5,
                                             factor.names = c("BGPComp", "Lang", "Range", "Union", "Optional")),
                                  randomize = F)
