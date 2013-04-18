use inc::Module::Install;

name 'AnyEvent-FIFO';
all_from 'lib/AnyEvent/FIFO.pm';
requires 'AnyEvent';
test_requires 'Test::More';
auto_install;
WriteAll;
