-- create table pacientes (
-- id serial primary key,
-- nome varchar(100) not null,
-- email varchar(100) unique not null,
-- cpf varchar(11) unique not null,
-- data_nascimento date not null,
-- data_cadastro timestamp default current_timestamp
-- )

-- create table especialidades (
-- id serial primary key,
-- nome varchar (50)unique not null
-- )

create table medicos (
id serial primary key,
especialidade_id int not null,
nome varchar(100)not null,
crm varchar(20) unique not null,
valor_consulta numeric(10, 2) not null check (valor_consulta > 0),

constraint fk_medico_especialidade
foreign key (especialidade_id)
references especialidade(id)
on delete restrict
)



)
