class PagesController < ApplicationController
  # GET /pages
  def index
    @pages = Page.page(params[:page]).per(20)
    auth!
  end

  # GET /pages/1
  def show
    @page = Page.find_by(slug: params[:id])
    @file_path = File.join(Rails.root, "app", "views", "pages", @page.title.parameterize + ".#{@page.language}" +".md")
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, space_after_headers: true)
    auth!
  end

  # GET /pages/new
  def new
    @page = Page.new
    auth!
  end

  # GET /pages/1/edit
  def edit
    @page = Page.find_by(slug: params[:id])
    @file_path = File.join(Rails.root, "app", "views", "pages", @page.title.parameterize + ".#{@page.language}" +".md")
    auth!
  end

  # POST /pages
  def create
    @page = Page.new(page_params)
    auth!
    if @page.save
      redirect_to @page, notice: t(:was_created, name: @page.title, theobj: t(:page))
    else
      render action => 'new'
    end
  end

  # PATCH/PUT /pages/1
  def update
    @page = Page.find_by(slug: params[:id])
    auth!
    if @page.update(page_params)
      redirect_to @page, notice: t(:was_updated, name: @page.title, theobj: t(:page))
    else
      render action => 'edit'
    end
  end

  # DELETE /pages/1
  def destroy
    @page = Page.find_by(slug: params[:id])
    auth!
    @page.destroy
    redirect_to pages_url, notice: t(:was_deleted, name: @page.title, theobj: t(:page))
  end

  private
    # Only allow a trusted parameter "white list" through.
    def page_params
      params.require(:page).permit(:category, :language, :title, :body)
    end
end
