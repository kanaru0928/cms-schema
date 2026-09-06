import "@typespec/http";
import "@typespec/openapi";

using Http;
using OpenAPI;

@service(#{ title: "Kanaru.me API" })
@info(#{ version: "2.0.0" })
@doc("Kanaru.me のバックエンドAPIドキュメント")
namespace KanaruMeAPI;

union ArticleStatus {
  published: "published",
  unpublished: "unpublished",
}

union SortOrder {
  asc: "asc",
  desc: "desc",
}

model ArticleMetadata {
  slug: string;
  title: string;
  source: string;
  status: ArticleStatus;
  pv: numeric;
  createdAt: string;
  updatedAt: string;
  tags: string[];
  thumbnailUrl: string;
}

model ArticleDetail extends ArticleMetadata {
  content: string;
}

@error
model Error {
  error: string;
}

model DeleteSuccess {
  message: string;
}

model UpsertTextArticle {
  @minLength(1) @maxLength(200) title: string;
  @minLength(1) contentBody: string;
  @minLength(1) @maxLength(100) source: string;
  status: ArticleStatus;
  tags?: string[] = #[];
  @minLength(1) @maxLength(2000) thumbnailUrl: string;
}

model NotFoundResponse {
  @statusCode statusCode: 404;
  @body body: Error;
}

model UnauthorizedResponse {
  @statusCode statusCode: 401;
  @body body: Error;
}

model InternalServerErrorResponse {
  @statusCode statusCode: 500;
  @body body: Error;
}

@route("/api/articles")
@tag("Articles")
interface Articles {
  @get
  @summary("記事一覧を取得")
  @doc("記事の一覧を取得します。認証されていない場合は公開済み記事のみ返却されます。")
  list(
    @query tag?: string,
    @query status?: ArticleStatus,

    @query
    @minValue(1)
    @maxValue(100)
    limit?: int32,

    @query order?: SortOrder,
  ): ArticleMetadata[] | InternalServerErrorResponse | UnauthorizedResponse;

  @get
  @route("{slug}")
  @summary("記事詳細を取得")
  @doc("指定されたスラッグの記事詳細を取得します")
  read(@path @minLength(1) slug: string):
    | ArticleDetail
    | NotFoundResponse
    | InternalServerErrorResponse
    | UnauthorizedResponse;

  @delete
  @route("{slug}")
  @useAuth(BearerAuth)
  @summary("記事を削除")
  @doc("指定されたスラッグの記事を削除します（要認証）")
  delete(@path @minLength(1) slug: string):
    | DeleteSuccess
    | UnauthorizedResponse
    | NotFoundResponse
    | InternalServerErrorResponse;

  @put
  @route("{slug}")
  @useAuth(BearerAuth)
  @summary("記事を作成または更新")
  @doc("記事が存在しない場合は新規作成、存在する場合は全体を更新します（要認証）")
  upsert(@path @minLength(1) slug: string, @body body: UpsertTextArticle):
    | {
        @statusCode statusCode: 200;
        @body body: ArticleMetadata;
      }
    | {
        @statusCode statusCode: 201;
        @body body: ArticleMetadata;
      }
    | UnauthorizedResponse
    | InternalServerErrorResponse;
}
