use inc::Module::Install;

name 'AnyEvent-FIFO';
requires 'AnyEvent';
test_requires 'Test::More';
auto_set_repository;
WriteAll;