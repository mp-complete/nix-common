{ ... }:
{
  # @juicesharp/rpiv-todo — live todo overlay that survives /reload and
  # conversation compaction. Same hand-vendored deps as the other rpiv
  # extensions.
  # https://github.com/juicesharp/rpiv-mono/tree/main/packages/rpiv-todo
  pi.extensions.rpiv-todo = {
    pname = "@juicesharp/rpiv-todo";
    version = "1.20.0";
    hash = "sha512-+tRVFrR/WVc/78UQm0+w+goAIKNyO28Lzrfr9agnOfccIkk98M0T/hnGY8z1PjYkNDnDk+BETiOYhhLqJvuNcQ==";
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
