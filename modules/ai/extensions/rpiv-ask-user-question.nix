{ ... }:
{
  # @juicesharp/rpiv-ask-user-question — structured questionnaire the
  # model can use instead of guessing. Ships without a lockfile, so we
  # vendor its @juicesharp/rpiv-config + typebox deps by hand.
  # https://github.com/juicesharp/rpiv-mono/tree/main/packages/rpiv-ask-user-question
  pi.extensions.rpiv-ask-user-question = {
    pname = "@juicesharp/rpiv-ask-user-question";
    version = "1.20.0";
    hash = "sha512-nccqKqeKoMDO9EZtAotyA/OkHBj+tl2jJBBSpP+1Ndyf7fnU592AO8Ax2Xk9VywHOYVz2X/66d/wC3oFUekV5Q==";
    vendor = [
      {
        dir = "@juicesharp/rpiv-config";
        pname = "@juicesharp/rpiv-config";
        version = "1.20.0";
        hash = "sha512-eu/sEBDt/+9kP40yCtlu04kRUxkQNaG1APzNIgnt5dGsualcwruedLWX9vtt0Fg4NSCAlNx5b2r9VjcWgAJirQ==";
      }
      {
        dir = "typebox";
        pname = "typebox";
        version = "1.1.38";
        hash = "sha512-pZ0aQPmMmXoUvSbeuWf/Hzsc+avNw/Zd6VeE8CFgkVGWyuHPJvqeJJDeJqLve+K70LvjYIoleGcoJHPT17cWoA==";
      }
    ];
  };
}
