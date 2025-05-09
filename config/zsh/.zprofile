
alias artisan="php artisan"
alias artisan-coverage="docker run -e "XDEBUG_MODE=coverage" -it --rm -v "${PWD}:/workdir" -w /workdir webdevops/php-dev:8.2 php artisan test --coverage --coverage-html reports"

# Disable telemetry on Homebrew
export HOMEBREW_NO_ANALYTICS=1
eval "$(/opt/homebrew/bin/brew shellenv)"
