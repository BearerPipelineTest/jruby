exclude :test_AREF_fstring_key, "Depends on MRI-specific GC.stat key"
exclude :test_ASET_fstring_key, "due https://github.com/jruby/jruby/commit/f3f0091da7d98c5df285"
exclude :test_callcc, "needs investigation"
exclude :test_callcc_escape, "needs investigation"
exclude :test_callcc_iter_level, "needs investigation"
exclude :test_callcc_reenter, "needs investigation"
exclude :test_eql, "needs investigation"
exclude :test_fetch_error, "needs investigation"
exclude :test_inverse_hash, "needs investigation"
exclude :test_tainted_string_key, "taint is deprecated"

# These are all excluded as a group because we do not generally randomize hashes.
# We may want or need to follow MRI lead here if we are concerned about the other hashDOS vectors.
# See https://bugs.ruby-lang.org/issues/13002
exclude :test_float_hash_random, "JRuby does not randomize hash calculation for Hash"
exclude :test_integer_hash_random, "JRuby does not randomize hash calculation for Hash"
exclude :test_symbol_hash_random, "JRuby does not randomize hash calculation for Hash"
exclude :test_replace_memory_leak, "no working assert_no_memory_leak method"
exclude :test_exception_in_rehash_memory_leak, "no working assert_no_memory_leak method"
