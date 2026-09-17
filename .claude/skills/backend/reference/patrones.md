# Patrones de referencia — backend

Consulta la sección que necesites. Todo esto lo crea el bootstrap (`bootstrap.md`) o se copia
adaptando nombres. Symfony 8.1 · API Platform 4 · Doctrine ORM 3 · lexik/jwt 3.

## 1. `config/packages/security.yaml`

```yaml
security:
    password_hashers:
        Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface: 'auto'
    providers:
        app_user_provider:
            entity:
                class: App\Entity\User
                property: username
    firewalls:
        dev:
            pattern: ^/(_(profiler|wdt)|css|images|js)/
            security: false
        login:
            pattern: ^/api/login
            stateless: true
            json_login:
                check_path: /api/login_check
                username_path: username
                password_path: password
                success_handler: lexik_jwt_authentication.handler.authentication_success
                failure_handler: lexik_jwt_authentication.handler.authentication_failure
        api:
            pattern: ^/api
            stateless: true
            jwt: ~
    access_control:
        - { path: ^/api/login, roles: PUBLIC_ACCESS }
        - { path: ^/api/docs,  roles: PUBLIC_ACCESS }
        - { path: ^/api,       roles: IS_AUTHENTICATED_FULLY }
```

`config/routes.yaml`:

```yaml
api_login_check:
    path: /api/login_check
```

`config/packages/lexik_jwt_authentication.yaml`:

```yaml
lexik_jwt_authentication:
    secret_key: '%env(resolve:JWT_SECRET_KEY)%'
    public_key: '%env(resolve:JWT_PUBLIC_KEY)%'
    pass_phrase: '%env(JWT_PASSPHRASE)%'
    token_ttl: 3600
    api_platform:
        check_path: /api/login_check
        username_path: username
        password_path: password
```

## 2. `config/packages/api_platform.yaml`

```yaml
api_platform:
    title: 'API'
    version: '1.0.0'
    defaults:
        stateless: true
        pagination_items_per_page: 20          # mismo valor que app.config.js del frontend
        pagination_client_items_per_page: true
    formats:
        jsonld: ['application/ld+json']
        json:   ['application/json']
    serializer:
        hydra_prefix: false                    # member / totalItems / view sin prefijo hydra:
```

## 3. `config/packages/nelmio_cors.yaml` y `.env`

```yaml
nelmio_cors:
    defaults:
        origin_regex: true
        allow_origin: ['%env(CORS_ALLOW_ORIGIN)%']
        allow_methods: ['GET', 'OPTIONS', 'POST', 'PUT', 'PATCH', 'DELETE']
        allow_headers: ['Content-Type', 'Authorization', 'Accept']
        expose_headers: ['Link']
        max_age: 3600
    paths:
        '^/': null
```

```dotenv
DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"
CORS_ALLOW_ORIGIN='^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$'
```

## 4. `src/Entity/Trait/TimestampableTrait.php`

```php
<?php
declare(strict_types=1);

namespace App\Entity\Trait;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;

/** Requiere #[ORM\HasLifecycleCallbacks] en la entidad. Expón las fechas añadiendo 'timestamps:read' al normalizationContext. */
trait TimestampableTrait
{
    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    #[Groups(['timestamps:read'])]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    #[Groups(['timestamps:read'])]
    private ?\DateTimeImmutable $updatedAt = null;

    #[ORM\PrePersist]
    public function initTimestamps(): void
    {
        $now = new \DateTimeImmutable();
        $this->createdAt ??= $now;
        $this->updatedAt = $now;
    }

    #[ORM\PreUpdate]
    public function touchTimestamps(): void
    {
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function getCreatedAt(): ?\DateTimeImmutable { return $this->createdAt; }
    public function getUpdatedAt(): ?\DateTimeImmutable { return $this->updatedAt; }
}
```

## 5. Recurso con operaciones, grupos y filtros

```php
<?php
declare(strict_types=1);

namespace App\Entity;

use ApiPlatform\Doctrine\Orm\Filter\OrderFilter;
use ApiPlatform\Doctrine\Orm\Filter\SearchFilter;
use ApiPlatform\Metadata\{ApiFilter, ApiResource, Delete, Get, GetCollection, Patch, Post};
use App\Entity\Trait\TimestampableTrait;
use App\Repository\ProductRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: ProductRepository::class)]
#[ORM\HasLifecycleCallbacks]
#[ORM\Index(name: 'idx_product_status', columns: ['status'])]
#[ORM\UniqueConstraint(name: 'uniq_product_sku', columns: ['sku'])]
#[UniqueEntity('sku', message: 'Ya existe un producto con este SKU.')]
#[ApiResource(
    normalizationContext: ['groups' => ['product:read', 'timestamps:read']],
    denormalizationContext: ['groups' => ['product:write']],
    operations: [
        new GetCollection(security: "is_granted('ROLE_USER')"),
        new Get(security: "is_granted('ROLE_USER')"),
        new Post(security: "is_granted('ROLE_ADMIN')"),
        new Patch(security: "is_granted('EDIT', object)"),   // → ProductVoter
        new Delete(security: "is_granted('ROLE_ADMIN')"),
    ],
)]
#[ApiFilter(SearchFilter::class, properties: ['name' => 'partial', 'status' => 'exact'])]
#[ApiFilter(OrderFilter::class, properties: ['name', 'createdAt'])]
class Product
{
    use TimestampableTrait;

    #[ORM\Id, ORM\GeneratedValue, ORM\Column]
    #[Groups(['product:read'])]
    private ?int $id = null;

    #[ORM\Column(length: 120)]
    #[Assert\NotBlank, Assert\Length(min: 2, max: 120)]
    #[Groups(['product:read', 'product:write'])]
    private ?string $name = null;

    #[ORM\Column(length: 40)]
    #[Assert\NotBlank]
    #[Groups(['product:read', 'product:write'])]
    private ?string $sku = null;

    #[ORM\Column(length: 20)]
    #[Assert\Choice(['active', 'archived'])]
    #[Groups(['product:read', 'product:write'])]
    private string $status = 'active';

    #[ORM\ManyToOne(inversedBy: 'products')]
    #[ORM\JoinColumn(nullable: false)]
    #[Groups(['product:read', 'product:write'])]      // se escribe como IRI: "/api/categories/3"
    private ?Category $category = null;

    // getters y setters fluidos (setX(): static)
}
```

Repositorio con colección sin N+1:

```php
/** @return Product[] */
public function findActiveWithCategory(): array
{
    return $this->createQueryBuilder('p')
        ->addSelect('c')->join('p.category', 'c')
        ->andWhere('p.status = :status')->setParameter('status', 'active')
        ->orderBy('p.name', 'ASC')
        ->getQuery()->getResult();
}
```

## 6. Voter

```php
<?php
declare(strict_types=1);

namespace App\Security\Voter;

use App\Entity\Product;
use App\Entity\User;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Authorization\Voter\Vote;
use Symfony\Component\Security\Core\Authorization\Voter\Voter;

/** @extends Voter<string, Product> */
final class ProductVoter extends Voter
{
    public const EDIT = 'EDIT';
    public const DELETE = 'DELETE';

    protected function supports(string $attribute, mixed $subject): bool
    {
        return in_array($attribute, [self::EDIT, self::DELETE], true) && $subject instanceof Product;
    }

    protected function voteOnAttribute(string $attribute, mixed $subject, TokenInterface $token, ?Vote $vote = null): bool
    {
        $user = $token->getUser();
        if (!$user instanceof User) {
            return false;
        }
        if (in_array('ROLE_ADMIN', $user->getRoles(), true)) {
            return true;
        }

        return match ($attribute) {
            self::EDIT => $subject->getOwner() === $user,
            self::DELETE => false,
        };
    }
}
```

## 7. Processor (escritura con lógica) y Provider

```php
<?php
declare(strict_types=1);

namespace App\State\Processor;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Entity\User;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

/** En la operación: new Post(processor: UserPasswordHashProcessor::class). plainPassword es una propiedad NO mapeada con #[Groups(['user:write'])]. */
final readonly class UserPasswordHashProcessor implements ProcessorInterface
{
    public function __construct(
        #[Autowire(service: 'api_platform.doctrine.orm.state.persist_processor')]
        private ProcessorInterface $persist,
        private UserPasswordHasherInterface $hasher,
    ) {}

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        if ($data instanceof User && $data->getPlainPassword() !== null) {
            $data->setPassword($this->hasher->hashPassword($data, $data->getPlainPassword()));
            $data->setPlainPassword(null);
        }

        return $this->persist->process($data, $operation, $uriVariables, $context);
    }
}
```

Para asignar el dueño en un POST: mismo patrón, `$data->setOwner($this->security->getUser())`
antes de delegar en `$persist`. Para lecturas calculadas: `ProviderInterface` que devuelve un
DTO `Output` y se declara con `provider:` en la operación.

## 8. Endpoint custom (no es un recurso)

```php
<?php
declare(strict_types=1);

namespace App\Controller\Api;

use App\Entity\User;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/me', name: 'api_me', methods: ['GET'])]
final class MeController extends AbstractController
{
    public function __invoke(): JsonResponse
    {
        /** @var User $user */
        $user = $this->getUser();

        return $this->json(['id' => $user->getId(), 'username' => $user->getUserIdentifier(), 'roles' => $user->getRoles()]);
    }
}
```

Con cuerpo o query: `#[MapRequestPayload] SalesReportInput $input` / `#[MapQueryString]` sobre
un DTO con constraints; Symfony responde `422` RFC 7807 solo. El controller delega en un Service
y devuelve `$this->json($service->generate($input))`. Conflicto de negocio →
`throw new ConflictHttpException('...')` (409).

## 9. Fixtures

```php
<?php
declare(strict_types=1);

namespace App\DataFixtures;

use App\Entity\User;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

final class AppFixtures extends Fixture
{
    public function __construct(private readonly UserPasswordHasherInterface $hasher) {}

    public function load(ObjectManager $manager): void
    {
        foreach ([['admin', ['ROLE_ADMIN']], ['user', []]] as [$username, $roles]) {
            $user = (new User())->setUsername($username)->setRoles($roles);
            $user->setPassword($this->hasher->hashPassword($user, 'pass_1234'));
            $manager->persist($user);
        }
        $manager->flush();
    }
}
```

## 10. Comando de importación (idempotente, por lotes)

```php
#[AsCommand(name: 'app:import:products', description: 'Importa productos desde un CSV; idempotente por sku')]
final class ImportProductsCommand extends Command
{
    public function __construct(private readonly ProductImporter $importer) { parent::__construct(); }

    protected function configure(): void { $this->addArgument('file', InputArgument::REQUIRED); }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        // El importer: valida TODO el archivo antes de escribir; upsert por clave natural;
        // lotes de 200 con flush() + clear() dentro de una transacción por lote.
        $r = $this->importer->import($input->getArgument('file'));
        $output->writeln(sprintf('leídas %d · insertadas %d · actualizadas %d · rechazadas %d', $r->read, $r->inserted, $r->updated, $r->rejected));

        return $r->rejected > 0 ? Command::FAILURE : Command::SUCCESS;
    }
}
```
