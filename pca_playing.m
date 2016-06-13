%coeff_f=pca(nm_img_list_foreground');

figure
histogram(sqrt(sum(coeff_f(:,1:50).^2,2)))
hold on;
histogram(sqrt(sum(coeff_f(:,1:100).^2,2)))
histogram(sqrt(sum(coeff_f(:,1:200).^2,2)))


coeff_img=pca(nm_img_list');

figure
ax=gca;

hist1=histogram(sqrt(sum(coeff_img(:,1:2).^2,2)));
hold on;
hist2=histogram(sqrt(sum(coeff_img(:,1:10).^2,2)));
hist3=histogram(sqrt(sum(coeff_img.^2,2)));
