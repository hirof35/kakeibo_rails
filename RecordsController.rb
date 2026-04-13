class RecordsController < ApplicationController
  before_action :set_record, only: %i[ edit update destroy ]

  def index
    # 今月の範囲
    @start_date = Date.today.beginning_of_month
    @end_date   = Date.today.end_of_month
  
    # 【修正ポイント】
    # 予算計算用には「今月」のデータを使い、
    # 履歴一覧（@records）には「全データ」または「最新10件」などを取得するように分ける
    
    # 全件表示する場合（日付制限なし）
    @records = Record.all
    
    # 予算計算用の集計（ここだけ今月に絞る）
    monthly_records = Record.where(date: @start_date..@end_date)
    
    # 予算計算
    budget_record = Budget.find_by(month: @start_date)
    @budget = budget_record ? budget_record.amount : 100000
    @total_spent = monthly_records.sum(:amount) || 0
    @remaining_budget = @budget - @total_spent
    @budget_percentage = @budget > 0 ? ([(@total_spent.to_f / @budget) * 100, 100].min).round : 0
  
    # カテゴリ集計も今月に絞る
    @categories = ["食費", "日用品", "娯楽", "交際費", "交通費", "その他"]
    @category_totals = monthly_records.group(:category).sum(:amount)
    @category_settings = CategoryBudget.pluck(:category, :amount).to_h
  end

  # --- ここから「保存」や「更新」に必要なメソッドを追加 ---

  def new
    @record = Record.new
  end

  def create
    @record = Record.new(record_params)
    if @record.save
      redirect_to records_path, notice: "記録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update_budget
    budget = Budget.find_or_initialize_by(month: Date.today.beginning_of_month)
    budget.amount = params[:amount]
    budget.save
    redirect_to records_path
  end

  def update_category_budget
    cb = CategoryBudget.find_or_initialize_by(category: params[:category])
    cb.amount = params[:amount]
    cb.save
    redirect_to records_path
  end

  def destroy
    @record.destroy
    redirect_to records_path, notice: "削除しました"
  end

  private

  def set_record
    @record = Record.find(params[:id])
  end

  def record_params
    params.require(:record).permit(:date, :amount, :category, :memo, :name)
  end
end
